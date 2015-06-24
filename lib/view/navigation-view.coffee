{CompositeDisposable} = require 'atom'
{CoveringView} = require './covering-view'

class NavigationView extends CoveringView

  @content: (navigator, editor) ->
    @div class: 'controls navigation', =>
      @text ' '
      @span class: 'pull-right', =>
        @button class: 'btn btn-xs', click: 'up', outlet: 'prevBtn', 'prev'
        @button class: 'btn btn-xs', click: 'down', outlet: 'nextBtn', 'next'

  initialize: (@navigator, editor) ->
    @subs = new CompositeDisposable

    super editor

    @prependKeystroke 'merge-conflicts:previous-unresolved', @prevBtn
    @prependKeystroke 'merge-conflicts:next-unresolved', @nextBtn

    @subs.add @navigator.conflict.onDidResolveConflict =>
      @deleteMarker @cover()
      @remove()
      @cleanup()

  cleanup: ->
    super
    @subs.dispose()

  cover: -> @navigator.separatorMarker

  up: -> @scrollTo @navigator.previousUnresolved()?.scrollTarget()

  down: -> @scrollTo @navigator.nextUnresolved()?.scrollTarget()

  conflict: -> @navigator.conflict

  toString: -> "{NavView of: #{@conflict()}}"

module.exports =
  NavigationView: NavigationView
