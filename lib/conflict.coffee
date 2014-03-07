{$} = require 'atom'
_ = require 'underscore-plus'

class Side
  constructor: (@ref, @marker, @refBannerMarker) ->
    @conflict = null

  text: -> @lines.text()

  resolve: -> @conflict.resolution = @

  wasChosen: -> @conflict.resolution is @

class OurSide extends Side

  site: -> 1

  klass: -> 'ours'

  description: -> 'our changes'

class TheirSide extends Side

  site: -> 2

  klass: -> 'theirs'

  description: -> 'their changes'

CONFLICT_REGEX = /^<{7} (\S+)\n([^]*?)={7}\n([^]*?)>{7} (\S+)\n?/mg

module.exports =
class Conflict
  constructor: (@ours, @theirs, @parent, @separatorMarker) ->
    ours.conflict = @
    theirs.conflict = @
    @resolution = null

  @all: (editorView) ->
    results = []
    editor = editorView.getEditor()
    buffer = editor.getBuffer()
    buffer.scan CONFLICT_REGEX, (m) ->
      [x, ourRef, ourText, theirText, theirRef] = m.match
      [baseRow, baseCol] = m.range.start.toArray()

      ourLines = ourText.split /\n/
      ourRowStart = baseRow + 1
      ourRowEnd = ourRowStart + ourLines.length - 1

      ourBannerMarker = editor.markBufferRange(
        [[baseRow, 0], [ourRowStart, 0]])
      ourMarker = editor.markBufferRange(
        [[ourRowStart, 0], [ourRowEnd, 0]])

      ours = new OurSide(ourRef, ourMarker, ourBannerMarker)

      separatorMarker = editor.markBufferRange(
        [[ourRowEnd, 0], [ourRowEnd + 1, 0]])

      theirLines = theirText.split /\n/
      theirRowStart = ourRowEnd + 1
      theirRowEnd = theirRowStart + theirLines.length - 1

      theirMarker = editor.markBufferRange(
        [[theirRowStart, 0], [theirRowEnd, 0]])
      theirBannerMarker = editor.markBufferRange(
        [[theirRowEnd, 0], [m.range.end.row, 0]])

      theirs = new TheirSide(theirRef, theirMarker, theirBannerMarker)

      c = new Conflict(ours, theirs, null, separatorMarker)
      c.editorView = editorView
      results.push c
    results
