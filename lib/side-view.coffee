{View, $} = require 'atom'

module.exports =
class SideView extends View
  @content: (side, editorView) ->
    @div class: "side #{side.klass()} ui-site-#{side.site()}", =>
      @div class: 'controls', =>
        @label class: 'text-highlight', side.ref
        @span class: 'text-subtle', "// #{side.description()}"
        @button class: 'btn btn-xs pull-right', click: 'useMe', "Use Me"

  initialize: (@side, @editorView) ->
    @side.conflict.on "conflict:resolved", =>
      @side.buffer().delete @side.refBannerMarker.getBufferRange()
      if @side.wasChosen()
        @remark()
      else
        @side.buffer().delete @side.marker.getBufferRange()
      @hide()

    @appendTo @editorView.overlayer
    @reposition()
    @remark()

    @side.refBannerMarker.on "changed", =>
      @reposition(editorView)

    # The editor DOM isn't actually updated until editor:display-updated is
    # emitted, but you don't want to fire on *every* display-updated event.

    updateScheduled = true

    @side.marker.on "changed", =>
      updateScheduled = true

    editorView.on "editor:display-updated", =>
      if updateScheduled
        @remark(editorView)
        updateScheduled = false

  reposition: ->
    anchor = @editorView.renderedLines.offset()
    ref = @side.refBannerOffset()

    @offset top: ref.top + anchor.top
    @height @side.refBannerLine().height()

  remark: ->
    lines = @side.lines()
    unless @side.conflict.isResolved()
      lines.addClass("conflict-line #{@side.klass()}").removeClass("resolved")
    else
      lines.removeClass(@side.klass()).addClass("conflict-line resolved")

  useMe: ->
    @side.resolve()

  getModel: -> null
