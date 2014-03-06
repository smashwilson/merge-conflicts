{View, $} = require 'atom'

module.exports =
class SideView extends View
  @content: (side) ->
    @div class: "side ui-site-#{side.site}", =>
      @div class: 'controls', =>
        @label class: 'text-highlight', side.ref
        @span class: 'text-subtle', "// your changes"
        @button class: 'btn btn-xs pull-right', click: 'useMe', "Use Me"

  initialize: (@side) ->

  useMe: ->
    console.log "useMe clicked"

  getModel: -> null
