{$} = require 'atom'
_ = require 'underscore-plus'
Conflict = require './conflict'
SideView = require './side-view'
NavigationView = require './navigation-view'
ResolverView = require './resolver-view'

CONFLICT_CLASSES = "conflict-line resolved ours theirs parent dirty"
OUR_CLASSES = "conflict-line ours"
THEIR_CLASSES = "conflict-line theirs"
RESOLVED_CLASSES = "conflict-line resolved"
DIRTY_CLASSES = "conflict-line dirty"

module.exports =
class ConflictMarker

  constructor: (@editorView) ->
    @conflicts = Conflict.all(@editorView.getEditor())

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
          source: @

    if @conflicts
      @remark()
      @installEvents()
    else
      @conflictsResolved()

  installEvents: ->
    @editorView.on 'editor:display-updated', => @remark()

    @editorView.command 'merge-conflicts:accept-current', => @acceptCurrent()
    @editorView.command 'merge-conflicts:accept-ours', => @acceptOurs()
    @editorView.command 'merge-conflicts:accept-theirs', => @acceptTheirs()
    @editorView.command 'merge-conflicts:ours-then-theirs', => @acceptOursThenTheirs()
    @editorView.command 'merge-conflicts:theirs-then-ours', => @acceptTheirsThenOurs()
    @editorView.command 'merge-conflicts:next-unresolved', => @nextUnresolved()
    @editorView.command 'merge-conflicts:previous-unresolved', => @previousUnresolved()
    @editorView.command 'merge-conflicts:revert-current', => @revertCurrent()

    atom.on 'merge-conflicts:resolved', ({total, resolved}) =>
      @conflictsResolved() if total is resolved

  conflictsResolved: ->
    v.remove() for v in @coveringViews
    @editorView.removeClass 'conflicted'
    @editorView.append new ResolverView(@editor())

  remark: ->
    @editorView.renderedLines.children().removeClass(CONFLICT_CLASSES)
    @withConflictSideLines (lines, classes) -> lines.addClass classes

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
      point = @combineSides side.conflict.ours, side.conflict.theirs
      m = side.conflict.navigator.separatorMarker
      m.setTailBufferPosition point
      side.conflict.ours.resolve()

  acceptTheirsThenOurs: ->
    for side in @active()
      point = @combineSides side.conflict.theirs, side.conflict.ours
      m = side.conflict.theirs.refBannerMarker
      m.setTailBufferPosition point
      side.conflict.theirs.resolve()

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

  linesForMarker: (marker) ->
    fromBuffer = marker.getTailBufferPosition()
    fromScreen = @editor().screenPositionForBufferPosition fromBuffer
    toBuffer = marker.getHeadBufferPosition()
    toScreen = @editor().screenPositionForBufferPosition toBuffer

    low = @editorView.getFirstVisibleScreenRow()
    high = @editorView.getLastVisibleScreenRow()

    result = $()
    for row in _.range(fromScreen.row, toScreen.row)
      if low <= row and row <= high
        result = result.add @editorView.lineElementForScreenRow row
    result

  combineSides: (first, second) ->
    text = @editor().getTextInBufferRange second.marker.getBufferRange()
    e = first.marker.getBufferRange().end
    insertPoint = @editor().setTextInBufferRange([e, e], text).end
    first.marker.setHeadBufferPosition insertPoint
    insertPoint

  withConflictSideLines: (callback) ->
    for c in @conflicts
      if c.isResolved()
        callback(@linesForMarker(c.resolution.marker), RESOLVED_CLASSES)
        continue

      if c.ours.isDirty
        callback(@linesForMarker(c.ours.marker), DIRTY_CLASSES)
      else
        callback(@linesForMarker(c.ours.marker), OUR_CLASSES)

      if c.theirs.isDirty
        callback(@linesForMarker(c.theirs.marker), DIRTY_CLASSES)
      else
        callback(@linesForMarker(c.theirs.marker), THEIR_CLASSES)

  focusConflict: (conflict) ->
    st = conflict.ours.marker.getBufferRange().start
    @editor().setCursorBufferPosition st
