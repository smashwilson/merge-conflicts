{$} = require 'atom'
_ = require 'underscore-plus'
{Subscriber} = require 'emissary'

Conflict = require './conflict'
SideView = require './side-view'
NavigationView = require './navigation-view'
ResolverView = require './resolver-view'
{EditorAdapter} = require './editor-adapter'

module.exports =
class ConflictMarker

  Subscriber.includeInto this

  constructor: (@state, @editorView) ->
    @conflicts = Conflict.all(@state, @editorView.getModel())
    @adapter = EditorAdapter.adapt(@editorView)

    @editorView.addClass 'conflicted' if @conflicts

    @coveringViews = []
    for c in @conflicts
      @coveringViews.push new SideView(c.ours, @editorView)
      @coveringViews.push new NavigationView(c.navigator, @editorView)
      @coveringViews.push new SideView(c.theirs, @editorView)

      c.on 'conflict:resolved', =>
        unresolved = (v for v in @coveringViews when not v.conflict().isResolved())
        v.reposition() for v in unresolved
        resolvedCount = @conflicts.length - Math.floor(unresolved.length / 3)
        atom.emit 'merge-conflicts:resolved',
          file: @editor().getPath(),
          total: @conflicts.length, resolved: resolvedCount,
          source: this

    if @conflicts.length > 0
      cv.decorate() for cv in @coveringViews
      @installEvents()
      @focusConflict @conflicts[0]
    else
      atom.emit 'merge-conflicts:resolved',
        file: @editor().getPath(),
        total: 1, resolved: 1,
        source: this
      @conflictsResolved()

  installEvents: ->
    @subscribe @editor(), 'contents-modified', => @detectDirty()
    @subscribe @editorView, 'editor:will-be-removed', => @cleanup()

    @editorView.command 'merge-conflicts:accept-current', => @acceptCurrent()
    @editorView.command 'merge-conflicts:accept-ours', => @acceptOurs()
    @editorView.command 'merge-conflicts:accept-theirs', => @acceptTheirs()
    @editorView.command 'merge-conflicts:ours-then-theirs', => @acceptOursThenTheirs()
    @editorView.command 'merge-conflicts:theirs-then-ours', => @acceptTheirsThenOurs()
    @editorView.command 'merge-conflicts:next-unresolved', => @nextUnresolved()
    @editorView.command 'merge-conflicts:previous-unresolved', => @previousUnresolved()
    @editorView.command 'merge-conflicts:revert-current', => @revertCurrent()

    @subscribe atom, 'merge-conflicts:resolved', ({total, resolved, file}) =>
      if file is @editor().getPath() and total is resolved
        @conflictsResolved()

  cleanup: ->
    @unsubscribe()
    v.remove() for v in @coveringViews
    @editorView.removeClass 'conflicted'

  conflictsResolved: ->
    @cleanup()
    @editorView.append new ResolverView(@editor())

  detectDirty: ->
    # Only detect dirty regions within CoveringViews that have a cursor within them.
    potentials = []
    for c in @editor().getCursors()
      for v in @coveringViews
        potentials.push(v) if v.includesCursor(c)

    v.detectDirty() for v in _.uniq(potentials)

  acceptCurrent: ->
    sides = @active()

    # Do nothing if you have cursors in *both* sides of a single conflict.
    duplicates = []
    seen = {}
    for side in sides
      if side.conflict of seen
        duplicates.push side
        duplicates.push seen[side.conflict]
      seen[side.conflict] = side
    sides = _.difference sides, duplicates

    side.resolve() for side in sides

  acceptOurs: -> side.conflict.ours.resolve() for side in @active()

  acceptTheirs: -> side.conflict.theirs.resolve() for side in @active()

  acceptOursThenTheirs: ->
    for side in @active()
      @combineSides side.conflict.ours, side.conflict.theirs

  acceptTheirsThenOurs: ->
    for side in @active()
      @combineSides side.conflict.theirs, side.conflict.ours

  nextUnresolved: ->
    final = _.last @active()
    if final?
      n = final.conflict.navigator.nextUnresolved()
      @focusConflict(n) if n?
    else
      orderedCursors = _.sortBy @editor().getCursors(), (c) ->
        c.getBufferPosition().row
      lastCursor = _.last orderedCursors
      return unless lastCursor?

      pos = lastCursor.getBufferPosition()
      firstAfter = null
      for c in @conflicts
        p = c.ours.marker.getBufferRange().start
        if p.isGreaterThanOrEqual(pos) and not firstAfter?
          firstAfter = c
      return unless firstAfter?

      if firstAfter.isResolved()
        target = firstAfter.navigator.nextUnresolved()
      else
        target = firstAfter
      @focusConflict target

  previousUnresolved: ->
    initial = _.first @active()
    if initial?
      p = initial.conflict.navigator.previousUnresolved()
      @focusConflict(p) if p?
    else
      orderedCursors = _.sortBy @editor().getCursors(), (c) ->
        c.getBufferPosition().row
      firstCursor = _.first orderedCursors
      return unless firstCursor?

      pos = firstCursor.getBufferPosition()
      lastBefore = null
      for c in @conflicts
        p = c.ours.marker.getBufferRange().start
        if p.isLessThanOrEqual pos
          lastBefore = c
      return unless lastBefore?

      if lastBefore.isResolved()
        target = lastBefore.navigator.previousUnresolved()
      else
        target = lastBefore
      @focusConflict target

  revertCurrent: ->
    for side in @active()
      for view in @coveringViews when view.conflict() is side.conflict
        view.revert() if view.isDirty()

  active: ->
    positions = (c.getBufferPosition() for c in @editor().getCursors())
    matching = []
    for c in @conflicts
      for p in positions
        if c.ours.marker.getBufferRange().containsPoint p
          matching.push c.ours
        if c.theirs.marker.getBufferRange().containsPoint p
          matching.push c.theirs
    matching

  editor: -> @editorView.getEditor()

  linesForMarker: (marker) -> @adapter.linesForMarker(marker)

  combineSides: (first, second) ->
    text = @editor().getTextInBufferRange second.marker.getBufferRange()
    e = first.marker.getBufferRange().end
    insertPoint = @editor().setTextInBufferRange([e, e], text).end
    first.marker.setHeadBufferPosition insertPoint
    first.followingMarker.setTailBufferPosition insertPoint
    first.resolve()

  focusConflict: (conflict) ->
    st = conflict.ours.marker.getBufferRange().start
    @editorView.scrollToBufferPosition st, center: true
    @editor().setCursorBufferPosition st, autoscroll: false
