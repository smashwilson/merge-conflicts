{$} = require 'space-pen'
{Emitter} = require 'atom'
_ = require 'underscore-plus'

{Side, OurSide, TheirSide, BaseSide} = require './side'
{Navigator} = require './navigator'

CONFLICT_REGEX = ///
  ^<{7}\ (.+)\r?\n([^]*?)
  # Base side may contain nested conflict markers.
  # Refer: http://stackoverflow.com/questions/16990657/git-merge-diff3-style-need-explanation
  (?:\|{7}\ (.+)\r?\n((?:(?:<{7}[^]*?>{7})|[^])*?))?
  ={7}\r?\n([^]*?)
  >{7}\ (.+)(?:\r?\n)?
  ///mg

INVALID = null
TOP = 'top'
BASE = 'base'
MIDDLE = 'middle'
BOTTOM = 'bottom'

# Private: ConflictParser discovers git conflict markers in a corpus of text and constructs Conflict
# instances that mark the correct lines.
#
class ConflictParser

  # Common options used to construct markers.
  options =
    persistent: false
    invalidate: 'never'

  # Private: Initialize a parser to operate on a specific TextEditor.
  #
  # state [MergeState] - Repository-wide conflict resolution state.
  # editor [TextEditor] - An editor containing text that may include one or more conflicts.
  #
  constructor: (@state, @editor) ->
    @position = INVALID

  # Private: Begin handling the result of a CONFLICT_REGEX match.
  #
  # m [Array] - The match object returned from CONFLICT_REGEX.
  #
  start: (@m) ->
    @startRow = @m.range.start.row
    @endRow = @m.range.end.row

    @chunks = @m.match
    @chunks.shift()

    @currentRow = @startRow
    @position = TOP
    @previousSide = null

  # Private: Complete handling of an individual CONFLICT_REGEX match.
  #
  finish: ->
    @previousSide.followingMarker = @previousSide.refBannerMarker

  # Private: Mark the current lines as "ours".
  #
  # Returns [Side] marking the current conflict's side.
  #
  markOurs: -> @_markHunk OurSide

  # Private: Mark the current lines as "base".
  #
  # Returns [Side] marking the base of conflict, or null if no base conflict marker is found.
  #
  markBase: -> @_markHunk BaseSide

  # Private: Mark the current lines as a separator.
  #
  # Returns [Navigator] containing a marker to the separator line.
  #
  markSeparator: ->
    unless @position is MIDDLE
      throw new Error("Unexpected position for separator: #{@position}")
    @position = BOTTOM

    sepRowStart = @currentRow
    sepRowEnd = @_advance 1

    marker = @editor.markBufferRange(
      [[sepRowStart, 0], [sepRowEnd, 0]], @options
    )

    # @previousSide should always be populated because @position is MIDDLE.
    @previousSide.followingMarker = marker

    new Navigator(marker)

  # Private: Mark the current lines as "theirs".
  #
  # Returns [Side] marking the current conflict's side.
  #
  markTheirs: -> @_markHunk TheirSide

  # Private: Mark the current lines and construct a Side of the appropriate class.
  #
  # sideKlass [Class] Side subclass to construct.
  # returns [sideKlass] marking the current lines.
  #
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

        @position = BASE
      when BASE
        @position = MIDDLE

        ref = @chunks.shift()
        text = @chunks.shift()
        # base is optional
        return null unless text
        lines = text.split /\n/

        bannerRowStart = @currentRow
        bannerRowEnd = rowStart = @_advance 1
        rowEnd = @_advance lines.length - 1
      when BOTTOM
        text = @chunks.shift()
        ref = @chunks.shift()
        lines = text.split /\n/

        rowStart = @currentRow
        bannerRowStart = rowEnd = @_advance lines.length - 1
        bannerRowEnd = @_advance 1

        @position = INVALID
      else
        throw new Error("Unexpected position for side: #{@position}")

    bannerMarker = @editor.markBufferRange(
      [[bannerRowStart, 0], [bannerRowEnd, 0]], @options
    )
    marker = @editor.markBufferRange(
      [[rowStart, 0], [rowEnd, 0]], @options
    )

    @previousSide.followingMarker = bannerMarker if sidePosition is BASE

    side = new sideKlass(text, ref, marker, bannerMarker, sidePosition)
    @previousSide = side
    side

  # Private: Advance the row counter.
  #
  # rowCount [Integer] The number of rows to advance.
  #
  _advance: (rowCount) -> @currentRow += rowCount

# Public: Model an individual conflict parsed from git's automatic conflict resolution output.
#
class Conflict

  # Private: Initialize a new Conflict with its constituent Sides, Navigator, and the MergeState
  # it belongs to.
  #
  # ours [Side] the lines of this conflict that the current user contributed (by our best guess).
  # theirs [Side] the lines of this conflict that another contributor created.
  # base [Side] the lines of merge base of this conflict. Optional.
  # navigator [Navigator] maintains references to surrounding Conflicts in the original file.
  # state [MergeState] repository-wide information about the current merge.
  #
  constructor: (@ours, @theirs, @base, @navigator, @state) ->
    @emitter = new Emitter

    @ours.conflict = this
    @theirs.conflict = this
    @base?.conflict = this
    @navigator.conflict = this
    @resolution = null

  # Public: Has this conflict been resolved in any way?
  #
  # Return [Boolean]
  #
  isResolved: -> @resolution?

  # Public: Attach an event handler to be notified when this conflict is resolved.
  #
  # callback [Function]
  #
  onDidResolveConflict: (callback) ->
    @emitter.on 'resolve-conflict', callback

  # Public: Specify which Side is to be kept. Note that either side may have been modified by the
  # user prior to resolution. Notify any subscribers.
  #
  # side [Side] our changes or their changes.
  #
  resolveAs: (side) ->
    @resolution = side
    @emitter.emit 'resolve-conflict'

  # Public: Locate the position that the editor should scroll to in order to make this conflict
  # visible.
  #
  # Return [Point] buffer coordinates
  #
  scrollTarget: -> @ours.marker.getTailBufferPosition()

  # Public: Audit all Marker instances owned by subobjects within this Conflict.
  #
  # Return [Array<Marker>]
  #
  markers: ->
    _.flatten [@ours.markers(), @theirs.markers(), @base?.markers() ? [], @navigator.markers()], true

  # Public: Console-friendly identification of this conflict.
  #
  # Return [String] that distinguishes this conflict from others.
  #
  toString: -> "[conflict: #{@ours} #{@theirs}]"

  # Public: Parse any conflict markers in a TextEditor's buffer and return a Conflict that contains
  # markers corresponding to each.
  #
  # state [MergeState] Repository-wide state of the merge.
  # editor [TextEditor] The editor to search.
  # return [Array<Conflict>] A (possibly empty) collection of parsed Conflicts.
  #
  @all: (state, editor) ->
    results = []
    previous = null
    marker = new ConflictParser(state, editor)

    editor.getBuffer().scan CONFLICT_REGEX, (m) ->
      marker.start m

      if state.isRebase
        theirs = marker.markTheirs()
        base = marker.markBase()
        nav = marker.markSeparator()
        ours = marker.markOurs()
      else
        ours = marker.markOurs()
        base = marker.markBase()
        nav = marker.markSeparator()
        theirs = marker.markTheirs()

      marker.finish()

      c = new Conflict(ours, theirs, base, nav, state)
      results.push c

      nav.linkToPrevious previous
      previous = c

    results

module.exports =
  Conflict: Conflict
