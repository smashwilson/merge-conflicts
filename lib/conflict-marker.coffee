{$} = require 'atom'
_ = require 'underscore-plus'
Conflict = require './conflict'
SideView = require './side-view'
NavigationView = require './navigation-view'

CONFLICT_CLASSES = "conflict-line resolved ours theirs parent"
OUR_CLASSES = "conflict-line ours"
THEIR_CLASSES = "conflict-line theirs"

module.exports =
class ConflictMarker

  constructor: (@editorView) ->
    @conflicts = Conflict.all(@editorView.getEditor())
    for c in @conflicts
      new SideView(c.ours, @editorView)
      new SideView(c.theirs, @editorView)
      new NavigationView(c.navigator, @editorView)

    if @conflicts
      @editorView.addClass 'conflicted'
      @remark()
      @editorView.on "editor:display-updated", => @remark()

  ourLines: -> @linesForMarker(c.ours.marker) for c in @conflicts

  theirLines: -> @linesForMarker(c.theirs.marker) for c in @conflicts

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

  remark: ->
    @editorView.renderedLines.removeClass(CONFLICT_CLASSES)
    batch.addClass(OUR_CLASSES) for batch in @ourLines()
    batch.addClass(THEIR_CLASSES) for batch in @theirLines()
