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
    @appendTo editorView.overlayer
    @reposition(editorView)

    @side.refBannerMarker.on "changed", =>
      @reposition(editorView)

  reposition: (editorView, initial) ->
    # @side.lines().addClass("conflict-line #{@side.klass()}")
    anchor = editorView.renderedLines.offset()
    ref = @side.refBannerOffset()

    @offset top: ref.top + anchor.top
    @height @side.refBannerLine().height()

  useMe: ->
    @side.resolve()

  getModel: -> null
