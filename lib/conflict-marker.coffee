{$} = require 'space-pen'
_ = require 'underscore-plus'
{Emitter, CompositeDisposable} = require 'atom'

Conflict = require './conflict'
SideView = require './side-view'
NavigationView = require './navigation-view'
ResolverView = require './resolver-view'

module.exports =
class ConflictMarker

  constructor: (@state, @editor, @pkg) ->
    @subs = new CompositeDisposable

    @conflicts = Conflict.all(@state, @editor)

    @coveringViews = []
    for c in @conflicts
      @coveringViews.push new SideView(c.ours, @editor)
      @coveringViews.push new NavigationView(c.navigator, @editor)
      @coveringViews.push new SideView(c.theirs, @editor)

      @subs.add c.onDidResolveConflict =>
        unresolved = (v for v in @coveringViews when not v.conflict().isResolved())
        resolvedCount = @conflicts.length - Math.floor(unresolved.length / 3)
        @pkg.didResolveConflict
          file: @editor.getPath(),
          total: @conflicts.length, resolved: resolvedCount,
          source: this

    if @conflicts.length > 0
      atom.views.getView(@editor).classList.add 'conflicted'

      cv.decorate() for cv in @coveringViews
      @installEvents()
      @focusConflict @conflicts[0]
    else
      @pkg.didResolveConflict
        file: @editor.getPath(),
        total: 1, resolved: 1,
        source: this
      @conflictsResolved()

  installEvents: ->
    @subs.add @editor.onDidStopChanging => @detectDirty()
    @subs.add @editor.onDidDestroy => @cleanup()

    @subs.add atom.commands.add 'atom-text-editor',
      'merge-conflicts:accept-current': => @acceptCurrent(),
      'merge-conflicts:accept-ours': => @acceptOurs(),
      'merge-conflicts:accept-theirs': => @acceptTheirs(),
      'merge-conflicts:ours-then-theirs': => @acceptOursThenTheirs(),
      'merge-conflicts:theirs-then-ours': => @acceptTheirsThenOurs(),
      'merge-conflicts:next-unresolved': => @nextUnresolved(),
      'merge-conflicts:previous-unresolved': => @previousUnresolved(),
      'merge-conflicts:revert-current': => @revertCurrent()

    @subs.add @pkg.onDidResolveConflict ({total, resolved, file}) =>
      if file is @editor.getPath() and total is resolved
        @conflictsResolved()

    @subs.add @pkg.onDidCompleteConflictResolution => @shutdown()
    @subs.add @pkg.onDidQuitConflictResolution => @shutdown()

  cleanup: ->
    atom.views.getView(@editor).classList.remove 'conflicted'
    v.remove() for v in @coveringViews

  conflictsResolved: ->
    @cleanup()
    atom.workspace.addTopPanel item: new ResolverView(@editor, @pkg)

  # Public: The package is shutting down, either because everything has been resolved or the user
  # is quitting prematurely.
  #
  shutdown: ->
    for c in @conflicts
      m.destroy() for m in c.markers()
    @subs.dispose()

  detectDirty: ->
    # Only detect dirty regions within CoveringViews that have a cursor within them.
    potentials = []
    for c in @editor.getCursors()
      for v in @coveringViews
        potentials.push(v) if v.includesCursor(c)

    v.detectDirty() for v in _.uniq(potentials)

  acceptCurrent: ->
    return unless @editor is atom.workspace.getActiveTextEditor()

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

  acceptOurs: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    side.conflict.ours.resolve() for side in @active()

  acceptTheirs: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    side.conflict.theirs.resolve() for side in @active()

  acceptOursThenTheirs: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    for side in @active()
      @combineSides side.conflict.ours, side.conflict.theirs

  acceptTheirsThenOurs: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    for side in @active()
      @combineSides side.conflict.theirs, side.conflict.ours

  nextUnresolved: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    final = _.last @active()
    if final?
      n = final.conflict.navigator.nextUnresolved()
      @focusConflict(n) if n?
    else
      orderedCursors = _.sortBy @editor.getCursors(), (c) ->
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
      return unless target?

      @focusConflict target

  previousUnresolved: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    initial = _.first @active()
    if initial?
      p = initial.conflict.navigator.previousUnresolved()
      @focusConflict(p) if p?
    else
      orderedCursors = _.sortBy @editor.getCursors(), (c) ->
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
      return unless target?

      @focusConflict target

  revertCurrent: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    for side in @active()
      for view in @coveringViews when view.conflict() is side.conflict
        view.revert() if view.isDirty()

  active: ->
    positions = (c.getBufferPosition() for c in @editor.getCursors())
    matching = []
    for c in @conflicts
      for p in positions
        if c.ours.marker.getBufferRange().containsPoint p
          matching.push c.ours
        if c.theirs.marker.getBufferRange().containsPoint p
          matching.push c.theirs
    matching

  combineSides: (first, second) ->
    text = @editor.getTextInBufferRange second.marker.getBufferRange()
    e = first.marker.getBufferRange().end
    insertPoint = @editor.setTextInBufferRange([e, e], text).end
    first.marker.setHeadBufferPosition insertPoint
    first.followingMarker.setTailBufferPosition insertPoint
    first.resolve()

  focusConflict: (conflict) ->
    st = conflict.ours.marker.getBufferRange().start
    @editor.scrollToBufferPosition st, center: true
    @editor.setCursorBufferPosition st, autoscroll: false
