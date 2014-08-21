{$} = require 'atom'
_ = require 'underscore-plus'

class EditorAdapter

  constructor: (@view) ->
    @editor = @view.getEditor()

  append: (child) ->

  linesElement: ->

  linesForMarker: (marker) ->

  @adapt: (view) ->
    if view.hasClass 'react'
      new ReactAdapter(view)
    else
      new ClassicAdapter(view)


class ClassicAdapter extends EditorAdapter

  append: (child) -> child.appendTo @view.overlayer

  linesElement: -> @view.renderedLines

  linesForMarker: (marker) ->
    fromBuffer = marker.getTailBufferPosition()
    fromScreen = @editor.screenPositionForBufferPosition fromBuffer
    toBuffer = marker.getHeadBufferPosition()
    toScreen = @editor.screenPositionForBufferPosition toBuffer

    low = @view.getFirstVisibleScreenRow()
    high = @view.getLastVisibleScreenRow()

    result = $()
    for row in _.range(fromScreen.row, toScreen.row)
      if low <= row and row <= high
        result = result.add @view.lineElementForScreenRow row
    result

class ReactAdapter extends EditorAdapter

  append: (child) -> @view.appendToLinesView(child)

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
