{$} = require 'atom'
_ = require 'underscore-plus'

class EditorAdapter

  constructor: (@view) ->
    @editor = @view.getEditor()

  append: (child) ->

  linesElement: ->

  linesForMarker: (marker) ->

  @adapt: (view) -> new ReactAdapter(view)

class ReactAdapter extends EditorAdapter

  append: (child) ->
    @view.appendToLinesView child
    child.css('z-index', 2)

  linesElement: -> @view.find('.lines')

  linesForMarker: (marker) ->
    fromBuffer = marker.getTailBufferPosition()
    fromScreen = @editor.screenPositionForBufferPosition fromBuffer
    toBuffer = marker.getHeadBufferPosition()
    toScreen = @editor.screenPositionForBufferPosition toBuffer

    result = $()
    for row in _.range(fromScreen.row, toScreen.row)
      result = result.add @view.component.lineNodeForScreenRow(row)
    result

module.exports =
  EditorAdapter: EditorAdapter
