{View, $} = require 'atom'

module.exports =
class SideView extends View
  @content: (side) ->
    @div class: "side #{side.klass()} ui-site-#{side.site()}", =>
      @div class: 'controls', =>
        @label class: 'text-highlight', side.ref
        @span class: 'text-subtle', "// #{side.description()}"
        @button class: 'btn btn-xs pull-right', click: 'useMe', "Use Me"

  initialize: (@side) ->

  installIn: (editorView) ->
    @side.lines.addClass("conflict-line ours")
    @offset left: 0, top: @side.marker.position().top
    @height @side.marker.height()
    @appendTo editorView.find(".overlayer")

  useMe: ->
    console.log "useMe clicked"

  getModel: -> null
