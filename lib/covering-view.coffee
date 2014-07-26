{EditorView, View, $} = require 'atom'
_ = require 'underscore-plus'
{EditorAdapter} = require './editor-adapter'


class CoveringView extends View

  initialize: (@editorView) ->
    @adapter = EditorAdapter.adapt(@editorView)

    @adapter.append(this)
    @reposition()

    @cover().on "changed", => @reposition()

  # Override to specify the marker of the first line that should be covered.
  cover: -> null

  # Override to return the Conflict that this view is responsible for.
  conflict: -> null

  isDirty: -> false

  # Override to determine if the content of this Side has been modified.
  detectDirty: -> null

  # Override to apply a decoration to a marker as appropriate.
  decorate: -> null

  getModel: -> null

  reposition: ->
    marker = @cover()
    anchor = @adapter.linesElement().offset()
    ref = @offsetForMarker marker

    @offset top: ref.top + anchor.top
    @height @editorView.lineHeight

  editor: -> @editorView.getEditor()

  buffer: -> @editor().getBuffer()

  includesCursor: (cursor) -> false

  offsetForMarker: (marker) ->
    position = marker.getTailBufferPosition()
    @editorView.pixelPositionForBufferPosition position

  deleteMarker: (marker) ->
    @buffer().delete marker.getBufferRange()
    marker.destroy()

  scrollTo: (positionOrNull) ->
    @editor().setCursorBufferPosition positionOrNull if positionOrNull?

  prependKeystroke: (eventName, element) ->
    bindings = atom.keymap.keyBindingsMatchingElement @editorView
    for e in bindings when e.command is eventName
      original = element.text()
      element.text(_.humanizeKeystroke(e.keystroke) + " #{original}")

module.exports =
  CoveringView: CoveringView
