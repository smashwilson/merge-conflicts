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
    console.log "== Initial installation // #{@side.description()}"
    @reposition(editorView, true)
    @appendTo editorView.overlayer

    @side.refBannerMarker.on "changed", =>
      console.log ">> Banner marker changed // #{@side.description()}"
      @reposition(editorView)

  reposition: (editorView, initial) ->
    # @side.lines().addClass("conflict-line #{@side.klass()}")
    anchor = editorView.renderedLines.offset()
    ref = @side.refBannerOffset()
    if initial
      top = ref.top
    else
      top = ref.top + anchor.top

    console.log "anchor: #{anchor.top} moving to: #{top}"
    console.log "matched lines: #{@side.lines().text()}"

    @offset top: top
    @height @side.refBannerLine().height()

  useMe: ->
    @side.resolve()

  getModel: -> null
