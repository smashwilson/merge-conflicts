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
      @deleteMarker @side.marker unless @side.wasChosen()
      @hide()

    @detectDirty()

    @side.marker.on 'changed', (event) =>
      marker = @side.marker

      tailSame = event.oldTailBufferPosition.isEqual marker.getTailBufferPosition()
      headDifferent = not event.oldHeadBufferPosition.isEqual marker.getHeadBufferPosition()

      @detectDirty() if tailSame and headDifferent

  cover: -> @side.refBannerMarker

  conflict: -> @side.conflict

  useMe: -> @side.resolve()

  detectDirty: ->
    currentText = @editor().getTextInBufferRange @side.marker.getBufferRange()
    @isDirty = currentText isnt @side.originalText

  revert: ->
    @editor().setTextInBufferRange @side.marker.getBufferRange(),
      @side.originalText
