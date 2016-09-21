{CompositeDisposable} = require 'atom'
{CoveringView} = require './covering-view'

class SideView extends CoveringView

  @content: (side, editor) ->
    @div class: "side #{side.klass()} #{side.position} ui-site-#{side.site()}", =>
      @div class: 'controls', =>
        @label class: 'text-highlight', side.ref
        @span class: 'text-subtle', "// #{side.description()}"
        @span class: 'pull-right', =>
          @button class: 'btn btn-xs inline-block-tight revert', click: 'revert', outlet: 'revertBtn', 'Revert'
          @button class: 'btn btn-xs inline-block-tight', click: 'useMe', outlet: 'useMeBtn', 'Use Me'
          @button class: 'btn btn-xs inline-block-tight', click: 'useMeFirst', outlet: 'useMeFirstBtn', 'Use Me, Then Them'
          @button class: 'btn btn-xs inline-block-tight', click: 'useMeLast', outlet: 'useMeLastBtn', 'Use Them, Then Me'
          ## TODO: Add `title` attributes to describe these actions better?

  initialize: (@side, editor) ->
    @subs = new CompositeDisposable
    @decoration = null

    super editor

    @detectDirty()
    @prependKeystroke @side.eventName(), @useMeBtn
    @prependKeystroke 'merge-conflicts:revert-current', @revertBtn

  attached: ->
    super

    @decorate()
    @subs.add @side.conflict.onDidResolveConflict =>
      @deleteMarker @side.refBannerMarker
      @deleteMarker @side.marker unless @side.wasChosen()
      @remove()
      @cleanup()

  cleanup: ->
    super
    @subs.dispose()

  cover: -> @side.refBannerMarker

  decorate: ->
    @decoration?.destroy()

    return if @side.conflict.isResolved() && !@side.wasChosen()

    args =
      type: 'line'
      class: @side.lineClass()
    @decoration = @editor.decorateMarker(@side.marker, args)

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
    
  useMeFirst: ->
    ## FIXME: Use `ConflictedEditor#acceptOursThenTheirs` instead?
    ## @side.resolve()
    ## TODO: Get the _other_ side and resolve it, too...
    @decorate()
    
  useMeLast: ->
    ## FIXME: Use `ConflictedEditor#acceptTheirsThenOurs` instead?
    ## TODO: Get the _other_ side and resolve it, too...
    ## @side.resolve()
    @decorate()

  revert: ->
    @editor.setTextInBufferRange @side.marker.getBufferRange(), @side.originalText
    @decorate()

  detectDirty: ->
    currentText = @editor.getTextInBufferRange @side.marker.getBufferRange()
    @side.isDirty = currentText isnt @side.originalText

    @decorate()

    @removeClass 'dirty'
    @addClass 'dirty' if @side.isDirty

  toString: -> "{SideView of: #{@side}}"

module.exports =
  SideView: SideView
