{View, $} = require 'atom'
_ = require 'underscore-plus'

module.exports =
class CoveringView extends View

  initialize: (@editorView) ->
    @appendTo @editorView.overlayer
    @reposition()

    @cover().on "changed", => @reposition()

  # Override to specify the marker of the first line that should be covered.
  cover: -> null

  # Override to return the Conflict that this view is responsible for.
  conflict: -> null

  isDirty: -> false

  getModel: -> null

  reposition: ->
    marker = @cover()
    anchor = @editorView.renderedLines.offset()
    ref = @offsetForMarker marker

    @offset top: ref.top + anchor.top
    @height @editorView.lineHeight

  editor: -> @editorView.getEditor()

  buffer: -> @editor().getBuffer()

  offsetForMarker: (marker) ->
    position = marker.getTailBufferPosition()
    @editorView.pixelPositionForBufferPosition position

  deleteMarker: (marker) -> @buffer().delete marker.getBufferRange()

  scrollTo: (positionOrNull) ->
    @editor().setCursorBufferPosition positionOrNull if positionOrNull?

  prependKeystroke: (eventName, element) ->
    bindings = atom.keymap.keyBindingsMatchingElement @editorView
    for e in bindings when e.command is eventName
      original = element.text()
      element.text(_.humanizeKeystroke(e.keystroke) + " #{original}")
