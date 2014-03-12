CoveringView = require './covering-view'

module.exports =
class NavigationView extends CoveringView
  @content: (navigator, editorView) ->
    @div class: 'controls navigation', =>
      @text ' '
      @span class: 'pull-right', =>
        @button class: 'btn btn-xs', click: 'down', =>
          @span class: 'icon icon-arrow-down', 'prev'
        @button class: 'btn btn-xs', click: 'up', =>
          @span class: 'icon icon-arrow-up', 'next'

  initialize: (@navigator, editorView) ->
    super editorView

    @navigator.conflict.on 'conflict:resolved', =>
      @deleteMarker @cover()
      @hide()

  cover: -> @navigator.separatorMarker

  up: -> @scrollTo @navigator.previousUnresolved()?.scrollTarget()

  down: -> @scrollTo @navigator.nextUnresolved()?.scrollTarget()
