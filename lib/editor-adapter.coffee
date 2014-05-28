{EditorView} = require 'atom'

class EditorAdapter

  constructor: (@view) ->

  append: (child) ->

  linesElement: ->

  @adapt: (view) ->
    if view instanceof EditorView
      new ClassicAdapter(view)
    else
      new ReactAdapter(view)


class ClassicAdapter extends EditorAdapter

  append: (child) -> child.appendTo @view.overlayer

  linesElement: -> @view.renderedLines


class ReactAdapter extends EditorAdapter

  append: (child) -> @view.appendToLinesView(child)

  linesElement: -> @view.find('.lines')

module.exports =
  EditorAdapter: EditorAdapter
