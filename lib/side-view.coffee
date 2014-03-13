{View, $} = require 'atom'
CoveringView = require './covering-view'
_ = require 'underscore-plus'

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
    @description = "SideView for #{@side.description()}"

    @side.conflict.on 'conflict:resolved', =>
      @deleteMarker @side.refBannerMarker
      if @side.wasChosen()
        # @remark()
      else
        @deleteMarker @side.marker
      @hide()

  cover: -> @side.refBannerMarker

  remark: ->
    console.log "Remarking #{@description} ..."
    lines = @linesForMarker @side.marker
    classes = ["conflict-line"]
    unless @side.conflict.isResolved()
      classes.push @side.klass()
    else
      classes.push "resolved"

    toRemove = _.difference SIDE_CLASSES, classes
    console.log "Adding classes #{classes} to <#{lines.text()}> for #{@description}"
    console.log "Removing classes #{classes} from <#{lines.text()}> for #{@description}"
    console.log "Remarking completed."

  useMe: -> @side.resolve()

  getModel: -> null
