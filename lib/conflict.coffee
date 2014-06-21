{$} = require 'atom'
{Emitter} = require 'emissary'

{Side, OurSide, TheirSide} = require './side'
Navigator = require './navigator'

CONFLICT_REGEX = /^<{7} (.+)\r?\n([^]*?)={7}\r?\n([^]*?)>{7} (.+)(?:\r?\n)?/mg

INVALID = null
TOP = 'top'
MIDDLE = 'middle'
BOTTOM = 'bottom'

class Marker

  options =
    persistent: false
    invalidate: 'never'

  constructor: (@state, @editor) ->
    @position = INVALID

  start: (@m) ->
    @startRow = @m.range.start.row
    @endRow = @m.range.end.row

    @chunks = @m.match
    @chunks.shift()

    @currentRow = @startRow
    @position = TOP
    @previousSide = null

  finish: ->
    @previousSide.followingMarker = @previousSide.refBannerMarker

  markOurs: -> @_markHunk OurSide

  markSeparator: ->
    unless @position is MIDDLE
      throw new Error "Unexpected position for separator: #{@position}"
    @position = BOTTOM

    sepRowStart = @currentRow
    sepRowEnd = @_advance 1

    marker = @editor.markBufferRange(
      [[sepRowStart, 0], [sepRowEnd, 0]], @options
    )

    # @previousSide should always be populated because @position is MIDDLE.
    @previousSide.followingMarker = marker

    new Navigator marker

  markTheirs: -> @_markHunk TheirSide

  _markHunk: (sideKlass) ->
    sidePosition = @position
    switch @position
      when TOP
        ref = @chunks.shift()
        text = @chunks.shift()
        lines = text.split /\n/

        bannerRowStart = @currentRow
        bannerRowEnd = rowStart = @_advance 1
        rowEnd = @_advance lines.length - 1

        @position = MIDDLE
      when BOTTOM
        text = @chunks.shift()
        ref = @chunks.shift()
        lines = text.split /\n/

        rowStart = @currentRow
        bannerRowStart = rowEnd = @_advance lines.length - 1
        bannerRowEnd = @_advance 1

        @position = INVALID
      else
        throw new Error "Unexpected position for side: #{@position}"

    bannerMarker = @editor.markBufferRange(
      [[bannerRowStart, 0], [bannerRowEnd, 0]], @options
    )
    marker = @editor.markBufferRange(
      [[rowStart, 0], [rowEnd, 0]], @options
    )

    side = new sideKlass(text, ref, marker, bannerMarker, sidePosition)
    @previousSide = side
    side

  _advance: (rowCount) -> @currentRow += rowCount

module.exports =
class Conflict

  Emitter.includeInto this

  constructor: (@ours, @theirs, @parent, @navigator, @state) ->
    @ours.conflict = this
    @theirs.conflict = this
    @navigator.conflict = this
    @resolution = null

  isResolved: -> @resolution?

  resolveAs: (side) ->
    @resolution = side
    @emit "conflict:resolved"

  scrollTarget: -> @ours.marker.getTailBufferPosition()

  @all: (state, editor) ->
    results = []
    previous = null
    marker = new Marker state, editor

    editor.getBuffer().scan CONFLICT_REGEX, (m) ->
      marker.start m

      if state.isRebase
        theirs = marker.markTheirs()
        nav = marker.markSeparator()
        ours = marker.markOurs()
      else
        ours = marker.markOurs()
        nav = marker.markSeparator()
        theirs = marker.markTheirs()

      marker.finish()

      c = new Conflict(ours, theirs, null, nav, state)
      results.push c

      nav.linkToPrevious previous
      previous = c

    results
