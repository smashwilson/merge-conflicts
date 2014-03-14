{$} = require 'atom'
{Emitter} = require 'emissary'

{Side, OurSide, TheirSide} = require './side'
Navigator = require './navigator'

CONFLICT_REGEX = /^<{7} (\S+)\n([^]*?)={7}\n([^]*?)>{7} (\S+)\n?/mg

module.exports =
class Conflict

  Emitter.includeInto(this)

  constructor: (@ours, @theirs, @parent, @navigator) ->
    @ours.conflict = @
    @theirs.conflict = @
    @navigator.conflict = @
    @resolution = null

  isResolved: -> @resolution?

  resolveAs: (side) ->
    @resolution = side
    @emit("conflict:resolved")

  scrollTarget: -> @ours.marker.getTailBufferPosition()

  @all: (editor) ->
    results = []
    buffer = editor.getBuffer()
    previous = null

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
      ourText = editor.getTextInBufferRange ourMarker.getBufferRange()

      ours = new OurSide(ourRef, ourMarker, ourBannerMarker, ourText)

      separatorMarker = editor.markBufferRange(
        [[ourRowEnd, 0], [ourRowEnd + 1, 0]])

      theirLines = theirText.split /\n/
      theirRowStart = ourRowEnd + 1
      theirRowEnd = theirRowStart + theirLines.length - 1

      theirMarker = editor.markBufferRange(
        [[theirRowStart, 0], [theirRowEnd, 0]])
      theirBannerMarker = editor.markBufferRange(
        [[theirRowEnd, 0], [m.range.end.row, 0]])
      theirText = editor.getTextInBufferRange theirMarker.getBufferRange()

      theirs = new TheirSide(theirRef, theirMarker, theirBannerMarker, theirText)

      nav = new Navigator(separatorMarker)

      c = new Conflict(ours, theirs, null, nav)
      results.push c

      nav.linkToPrevious previous
      previous = c
    results
