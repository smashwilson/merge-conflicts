{View} = require 'atom'

module.exports =
class CoveringView extends View

  initialize: (@editorView) ->

  editor: -> @editorView.getEditor()

  buffer: -> @editor().getBuffer()

  linesForMarker: (marker) ->
    fromBuffer = marker.getTailBufferPosition()
    fromScreen = @editor().screenPositionForBufferPosition fromBuffer
    toBuffer = marker.getHeadBufferPosition()
    toScreen = @editor().screenPositionForBufferPosition toBuffer

    lines = @editorView.renderedLines.children('.line')
    lines.slice(fromScreen.row, toScreen.row)

  offsetForMarker: (marker) ->
    position = marker.getTailBufferPosition()
    @editorView.pixelPositionForBufferPosition position

  deleteMarker: (marker) -> @buffer().delete marker.getBufferRange()
