{View, $} = require 'space-pen'
_ = require 'underscore-plus'
{EditorAdapter} = require './editor-adapter'


class CoveringView extends View

  initialize: (@editor) ->
    @editorView = atom.views.getView @editor
    @adapter = EditorAdapter.adapt(@editorView)

    @adapter.append(this)
    @reposition()

    @cover().onDidChange => @reposition()

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
    anchor = $(@editorView).offset()
    ref = @offsetForMarker marker
    scrollTop = @editor.getScrollTop()

    @offset top: ref.top + anchor.top - scrollTop
    @height @editor.getLineHeightInPixels()

  buffer: -> @editor.getBuffer()

  includesCursor: (cursor) -> false

  offsetForMarker: (marker) ->
    position = marker.getTailBufferPosition()
    @editor.pixelPositionForBufferPosition position

  deleteMarker: (marker) ->
    @buffer().delete marker.getBufferRange()
    marker.destroy()

  scrollTo: (positionOrNull) ->
    @editor.setCursorBufferPosition positionOrNull if positionOrNull?

  prependKeystroke: (eventName, element) ->
    bindings = atom.keymap.findKeyBindings
      target: @editorView[0]
      command: eventName

    for e in bindings
      original = element.text()
      element.text(_.humanizeKeystroke(e.keystrokes) + " #{original}")

module.exports =
  CoveringView: CoveringView
