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

    @decoration = null

    @side.conflict.on 'conflict:resolved', =>
      @deleteMarker @side.refBannerMarker
      @deleteMarker @side.marker unless @side.wasChosen()
      @remove()

  cover: -> @side.refBannerMarker

  decorate: ->
    args =
      type: 'line'
      class: @side.lineClass()
    if @decoration?
      @decoration.update(args)
    else
      @decoration = @editor().decorateMarker(@side.marker, args)

  conflict: -> @side.conflict

  isDirty: -> @side.isDirty

  includesCursor: (cursor) ->
    m = @side.marker
    [h, t] = [m.getHeadBufferPosition(), m.getTailBufferPosition()]
    p = cursor.getBufferPosition()
    t.isLessThanOrEqual(p) and h.isGreaterThanOrEqual(p)

  useMe: ->
    @side.resolve()
    @decorate()

  revert: ->
    @editor().setTextInBufferRange @side.marker.getBufferRange(),
      @side.originalText
    @decorate()

  detectDirty: ->
    currentText = @editor().getTextInBufferRange @side.marker.getBufferRange()
    @side.isDirty = currentText isnt @side.originalText

    @decorate()

    @removeClass 'dirty'
    @addClass 'dirty' if @side.isDirty
