{View} = require 'atom'

module.exports =
class NavigationView extends View
  @content: (conflict) ->
    @div class: 'controls navigation', =>
      @text ' '
      @span class: 'pull-right', =>
        @button class: 'btn btn-xs', click: 'down', =>
          @span class: 'icon icon-arrow-small-down', 'prev'
        @button class: 'btn btn-xs', click: 'up', =>
          @span class: 'icon icon-arrow-small-up', 'next'

  initialize: (@conflict) ->

  installIn: (@editorView) ->
    @appendTo @editorView.overlayer
    @reposition()

    @conflict.separatorMarker.on "changed", =>
      @reposition()

  line: ->
    editor = @editorView.getEditor()
    position = @conflict.separatorMarker.getTailBufferPosition()
    screen = editor.screenPositionForBufferPosition position
    @editorView.renderedLines.children('.line').eq screen.row

  separatorOffset: ->
    position = @conflict.separatorMarker.getTailBufferPosition()
    @editorView.pixelPositionForBufferPosition position

  reposition: ->
    anchor = @editorView.renderedLines.offset()
    ref = @separatorOffset()

    @offset top: ref.top + anchor.top
    @height @line().height()

  up: ->

  down: ->
