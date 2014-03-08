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
    @side.conflict.on "conflict:resolved", =>
      @trimMarkerLines()
      if @side.wasChosen()
        @chosenAsResolution()
      else
        @rejectedAsResolution()
      @hide()

  installIn: (editorView) ->
    @appendTo editorView.overlayer
    @reposition(editorView)
    @remark(editorView)

    @side.refBannerMarker.on "changed", =>
      @reposition(editorView)

    updateScheduled = true

    @side.marker.on "changed", =>
      updateScheduled = true

    editorView.on "editor:display-updated", =>
      if updateScheduled
        @remark(editorView)
        updateScheduled = false

  reposition: (editorView) ->
    anchor = editorView.renderedLines.offset()
    ref = @side.refBannerOffset()

    @offset top: ref.top + anchor.top
    @height @side.refBannerLine().height()

  remark: (editorView) ->
    lines = @side.lines()
    unless @side.conflict.isResolved()
      lines.addClass("conflict-line #{@side.klass()}").removeClass("resolved")
    else
      lines.removeClass(@side.klass()).addClass("conflict-line resolved")

  trimMarkerLines: ->
    @side.buffer().delete @side.refBannerMarker.getBufferRange()

  chosenAsResolution: ->
    @remark()

  rejectedAsResolution: ->
    @side.buffer().delete @side.marker.getBufferRange()

  useMe: ->
    @side.resolve()

  getModel: -> null
