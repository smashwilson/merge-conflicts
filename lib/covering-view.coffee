{View, $} = require 'atom'
_ = require 'underscore-plus'

module.exports =
class CoveringView extends View

  initialize: (@editorView) ->
    @appendTo @editorView.overlayer
    @reposition()

    @cover().on "changed", => @reposition()

    @description = "undescribed CoveringView"

  # Override to specify the marker of the first line that should be covered.
  cover: -> null

  reposition: ->
    marker = @cover()
    anchor = @editorView.renderedLines.offset()
    ref = @offsetForMarker marker

    @offset top: ref.top + anchor.top
    @height @editorView.lineHeight

  editor: -> @editorView.getEditor()

  buffer: -> @editor().getBuffer()

  linesForMarker: (marker) ->
    fromBuffer = marker.getTailBufferPosition()
    fromScreen = @editor().screenPositionForBufferPosition fromBuffer
    toBuffer = marker.getHeadBufferPosition()
    toScreen = @editor().screenPositionForBufferPosition toBuffer

    result = $()
    for row in _.range(fromScreen.row, toScreen.row)
      result = result.add @editorView.lineElementForScreenRow row
    result

  offsetForMarker: (marker) ->
    position = marker.getTailBufferPosition()
    @editorView.pixelPositionForBufferPosition position

  deleteMarker: (marker) -> @buffer().delete marker.getBufferRange()

  scrollTo: (positionOrNull) ->
    @editor().setCursorBufferPosition positionOrNull if positionOrNull?
