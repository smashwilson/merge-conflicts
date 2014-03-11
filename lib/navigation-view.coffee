CoveringView = require './covering-view'

module.exports =
class NavigationView extends CoveringView
  @content: (conflict, editorView) ->
    @div class: 'controls navigation', =>
      @text ' '
      @span class: 'pull-right', =>
        @button class: 'btn btn-xs', click: 'down', =>
          @span class: 'icon icon-arrow-down', 'prev'
        @button class: 'btn btn-xs', click: 'up', =>
          @span class: 'icon icon-arrow-up', 'next'

  initialize: (@conflict, editorView) ->
    super editorView

    @conflict.on 'conflict:resolved', =>
      @deleteMarker @cover()
      @hide()

  cover: -> @conflict.separatorMarker

  up: ->

  down: ->
