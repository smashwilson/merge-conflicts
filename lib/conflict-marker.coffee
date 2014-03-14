{$} = require 'atom'
_ = require 'underscore-plus'
Conflict = require './conflict'
SideView = require './side-view'
NavigationView = require './navigation-view'

CONFLICT_CLASSES = "conflict-line resolved ours theirs parent dirty"
OUR_CLASSES = "conflict-line ours"
THEIR_CLASSES = "conflict-line theirs"
RESOLVED_CLASSES = "conflict-line resolved"
DIRTY_CLASSES = "conflict-line dirty"

module.exports =
class ConflictMarker

  constructor: (@editorView) ->
    @conflicts = Conflict.all(@editorView.getEditor())

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
          file: @editor().getPath(), total: @conflicts.length,
          resolved: resolvedCount

    if @conflicts
      @editorView.addClass 'conflicted'
      @remark()

      @editorView.on 'editor:display-updated', => @remark()

  remark: ->
    @editorView.renderedLines.children().removeClass(CONFLICT_CLASSES)
    @withConflictSideLines (lines, classes) -> lines.addClass classes

  active: ->
    positions = (c.getBufferPosition() for c in @editor().getCursors())
    matching = []
    for c in @conflicts
      for p in positions
        if c.ours.marker.getBufferRange().containsPoint p
          matching.push c
        if c.theirs.marker.getBufferRange().containsPoint p
          matching.push c
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
