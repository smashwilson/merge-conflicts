{$} = require 'space-pen'
_ = require 'underscore-plus'
{Emitter, CompositeDisposable} = require 'atom'

{Conflict} = require './conflict'

{SideView} = require './view/side-view'
{NavigationView} = require './view/navigation-view'
{ResolverView} = require './view/resolver-view'

# Public: Mediate conflict-related decorations and events on behalf of a specific TextEditor.
#
class ConflictedEditor

  # Public: Instantiate a new ConflictedEditor to manage the decorations and events of a specific
  # TextEditor.
  #
  # state [MergeState] - Merge-wide conflict state.
  # pkg [Emitter] - The package object containing event dispatch and subscription methods.
  # editor [TextEditor] - An editor containing text that, presumably, includes conflict markers.
  #
  constructor: (@state, @pkg, @editor) ->
    @subs = new CompositeDisposable
    @coveringViews = []
    @conflicts = []

  # Public: Locate Conflicts within this specific TextEditor.
  #
  # Install a pair of SideViews and a NavigationView for each Conflict discovered within the
  # editor's text. Subscribe to package events related to relevant Conflicts and broadcast
  # per-editor progress events as they are resolved. Install Atom commands related to conflict
  # navigation and resolution.
  #
  mark: ->
    @conflicts = Conflict.all(@state, @editor)

    @coveringViews = []
    for c in @conflicts
      @coveringViews.push new SideView(c.ours, @editor)
      @coveringViews.push new SideView(c.base, @editor) if c.base?
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

  # Private: Install Atom commands related to Conflict resolution and navigation on the TextEditor.
  #
  # Listen for package-global events that relate to the local Conflicts and dispatch them
  # appropriately.
  #
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

    @subs.add @pkg.onDidCompleteConflictResolution => @cleanup()
    @subs.add @pkg.onDidQuitConflictResolution => @cleanup()

  # Private: Undo any changes done to the underlying TextEditor.
  #
  cleanup: ->
    atom.views.getView(@editor).classList.remove 'conflicted' if @editor?

    for c in @conflicts
      m.destroy() for m in c.markers()

    v.remove() for v in @coveringViews

    @subs.dispose()

  # Private: Event handler invoked when all conflicts in this file have been resolved.
  #
  conflictsResolved: ->
    atom.workspace.addTopPanel item: new ResolverView(@editor, @state, @pkg)

  detectDirty: ->
    # Only detect dirty regions within CoveringViews that have a cursor within them.
    potentials = []
    for c in @editor.getCursors()
      for v in @coveringViews
        potentials.push(v) if v.includesCursor(c)

    v.detectDirty() for v in _.uniq(potentials)

  # Private: Command that accepts each side of a conflict that contains a cursor.
  #
  # Conflicts with cursors in both sides will be ignored.
  #
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

    @editor.transact ->
      side.resolve() for side in sides

  # Private: Command that accepts the "ours" side of the active conflict.
  #
  acceptOurs: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    @editor.transact =>
      side.conflict.ours.resolve() for side in @active()

  # Private: Command that accepts the "theirs" side of the active conflict.
  #
  acceptTheirs: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    @editor.transact =>
      side.conflict.theirs.resolve() for side in @active()

  # Private: Command that uses a composite resolution of the "ours" side followed by the "theirs"
  # side of the active conflict.
  #
  acceptOursThenTheirs: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    @editor.transact =>
      for side in @active()
        @combineSides side.conflict.ours, side.conflict.theirs

  # Private: Command that uses a composite resolution of the "theirs" side followed by the "ours"
  # side of the active conflict.
  #
  acceptTheirsThenOurs: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    @editor.transact =>
      for side in @active()
        @combineSides side.conflict.theirs, side.conflict.ours

  # Private: Command that navigates to the next unresolved conflict in the editor.
  #
  # If the cursor is on or after the final unresolved conflict in the editor, nothing happens.
  #
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

  # Private: Command that navigates to the previous unresolved conflict in the editor.
  #
  # If the cursor is on or before the first unresolved conflict in the editor, nothing happens.
  #
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

  # Private: Revert manual edits to the current side of the active conflict.
  #
  revertCurrent: ->
    return unless @editor is atom.workspace.getActiveTextEditor()
    for side in @active()
      for view in @coveringViews when view.conflict() is side.conflict
        view.revert() if view.isDirty()

  # Private: Collect a list of each Side of any Conflict within the editor that contains a cursor.
  #
  # Returns [Array<Side>]
  #
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

  # Private: Resolve a conflict by combining its two Sides in a specific order.
  #
  # first [Side] The Side that should occur first in the resolved text.
  # second [Side] The Side belonging to the same Conflict that should occur second in the resolved
  #   text.
  #
  combineSides: (first, second) ->
    text = @editor.getTextInBufferRange second.marker.getBufferRange()
    e = first.marker.getBufferRange().end
    insertPoint = @editor.setTextInBufferRange([e, e], text).end
    first.marker.setHeadBufferPosition insertPoint
    first.followingMarker.setTailBufferPosition insertPoint
    first.resolve()

  # Private: Scroll the editor and place the cursor at the beginning of a marked conflict.
  #
  # conflict [Conflict] Any conflict within the current editor.
  #
  focusConflict: (conflict) ->
    st = conflict.ours.marker.getBufferRange().start
    @editor.scrollToBufferPosition st, center: true
    @editor.setCursorBufferPosition st, autoscroll: false

module.exports =
  ConflictedEditor: ConflictedEditor
