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

    @side.conflict.on 'conflict:resolved', =>
      @deleteMarker @side.refBannerMarker
      if @side.wasChosen()
        @remark()
      else
        @deleteMarker @side.marker
      @hide()

    @remark()

    editorView.on "editor:display-updated", => @remark()

  cover: -> @side.refBannerMarker

  remark: ->
    lines = @linesForMarker @side.marker
    unless @side.conflict.isResolved()
      addClasses = "conflict-line #{@side.klass()}"
      removeClasses = "resolved"
    else
      addClasses = "conflict-line resolved"
      removeClasses = @side.klass()
    lines.removeClass(removeClasses).addClass(addClasses)

  useMe: -> @side.resolve()

  getModel: -> null
