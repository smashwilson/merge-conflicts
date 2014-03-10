{View, $} = require 'atom'
CoveringView = require './covering-view'

module.exports =
class SideView extends CoveringView
  @content: (side, editorView) ->
    @div class: "side #{side.klass()} ui-site-#{side.site()}", =>
      @div class: 'controls', =>
        @label class: 'text-highlight', side.ref
        @span class: 'text-subtle', "// #{side.description()}"
        @button class: 'btn btn-xs pull-right', click: 'useMe', "Use Me"

  initialize: (@side, editorView) ->
    super editorView

    @side.conflict.on "conflict:resolved", =>
      @deleteMarker @side.refBannerMarker
      if @side.wasChosen()
        @remark()
      else
        @deleteMarker @side.marker
      @hide()

    @remark()

    # The editor DOM isn't actually updated until editor:display-updated is
    # emitted, but you don't want to fire on *every* display-updated event.

    updateScheduled = true

    @side.marker.on "changed", => updateScheduled = true

    editorView.on "editor:display-updated", =>
      if updateScheduled
        @remark()
        updateScheduled = false

  cover: -> @side.refBannerMarker

  remark: ->
    lines = @linesForMarker @side.marker
    unless @side.conflict.isResolved()
      lines.addClass("conflict-line #{@side.klass()}").removeClass("resolved")
    else
      lines.removeClass(@side.klass()).addClass("conflict-line resolved")

  useMe: -> @side.resolve()

  getModel: -> null
