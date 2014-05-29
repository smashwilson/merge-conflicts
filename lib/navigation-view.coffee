{CoveringView} = require './covering-view'

module.exports =
class NavigationView extends CoveringView
  @content: (navigator, editorView) ->
    @div class: 'controls navigation', =>
      @text ' '
      @span class: 'pull-right', =>
        @button class: 'btn btn-xs', click: 'up', outlet: 'prevBtn', 'prev'
        @button class: 'btn btn-xs', click: 'down', outlet: 'nextBtn', 'next'

  initialize: (@navigator, editorView) ->
    super editorView

    @prependKeystroke 'merge-conflicts:previous-unresolved', @prevBtn
    @prependKeystroke 'merge-conflicts:next-unresolved', @nextBtn

    @navigator.conflict.on 'conflict:resolved', =>
      @deleteMarker @cover()
      @hide()

  cover: -> @navigator.separatorMarker

  up: -> @scrollTo @navigator.previousUnresolved()?.scrollTarget()

  down: -> @scrollTo @navigator.nextUnresolved()?.scrollTarget()

  conflict: -> @navigator.conflict
