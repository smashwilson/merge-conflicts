{$} = require 'atom'
_ = require 'underscore-plus'
Conflict = require './conflict'
SideView = require './side-view'
NavigationView = require './navigation-view'

CONFLICT_CLASSES = "conflict-line resolved ours theirs parent"
OUR_CLASSES = "conflict-line ours"
THEIR_CLASSES = "conflict-line theirs"
RESOLVED_CLASSES = "conflict-line resolved"

module.exports =
class ConflictMarker

  constructor: (@editorView) ->
    @conflicts = Conflict.all(@editorView.getEditor())

    @coveringViews = []
    for c in @conflicts
      @coveringViews.push new SideView(c.ours, @editorView)
      @coveringViews.push new SideView(c.theirs, @editorView)
      @coveringViews.push new NavigationView(c.navigator, @editorView)

      c.on 'conflict:resolved', => @repositionUnresolved()

    if @conflicts
      @editorView.addClass 'conflicted'
      @remark()

      @editorView.on 'editor:display-updated', => @remark()

  remark: ->
    @editorView.renderedLines.removeClass(CONFLICT_CLASSES)
    @ourLines().addClass(OUR_CLASSES)
    @theirLines().addClass(THEIR_CLASSES)
    @resolvedLines().addClass(RESOLVED_CLASSES)

  repositionUnresolved: ->
    for view in @coveringViews
      view.reposition() unless view.conflict().isResolved()

  ourLines: -> @linesForConflicts false, (c) -> c.ours.marker

  theirLines: -> @linesForConflicts false, (c) -> c.theirs.marker

  resolvedLines: -> @linesForConflicts true, (c) -> c.resolution.marker

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

  linesForConflicts: (resolved, markerCallback) ->
    results = $()
    for c in @conflicts
      if (resolved and c.isResolved()) or (not resolved and not c.isResolved())
        marker = markerCallback(c)
        results = results.add @linesForMarker marker
    results
