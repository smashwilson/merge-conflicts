{CoveringView} = require './covering-view'

module.exports =
class SideView extends CoveringView

  @content: (side, editorView) ->
    @div class: "side #{side.klass()} #{side.position} ui-site-#{side.site()}", =>
      @div class: 'controls', =>
        @label class: 'text-highlight', side.ref
        @span class: 'text-subtle', "// #{side.description()}"
        @span class: 'pull-right', =>
          @button class: 'btn btn-xs inline-block-tight revert', click: 'revert', outlet: 'revertBtn', 'Revert'
          @button class: 'btn btn-xs inline-block-tight', click: 'useMe', outlet: 'useMeBtn', 'Use Me'

  initialize: (@side, editorView) ->
    super editorView

    @detectDirty()
    @prependKeystroke @side.eventName(), @useMeBtn
    @prependKeystroke 'merge-conflicts:revert-current', @revertBtn

    @side.conflict.on 'conflict:resolved', =>
      @deleteMarker @side.refBannerMarker
      @deleteMarker @side.marker unless @side.wasChosen()
      @remove()

  cover: -> @side.refBannerMarker

  conflict: -> @side.conflict

  isDirty: -> @side.isDirty

  useMe: -> @side.resolve()

  revert: ->
    @editor().setTextInBufferRange @side.marker.getBufferRange(),
      @side.originalText

  detectDirty: ->
    currentText = @editor().getTextInBufferRange @side.marker.getBufferRange()
    @side.isDirty = currentText isnt @side.originalText

    @removeClass 'dirty'
    @addClass 'dirty' if @side.isDirty
