{$} = require 'space-pen'
{Emitter} = require 'atom'
_ = require 'underscore-plus'

{Side, OurSide, TheirSide, BaseSide} = require './side'
{Navigator} = require './navigator'

CONFLICT_START_REGEX = /^<{7} (.+)\r?\n/g

# Side positions
TOP = 'top'
BASE = 'base'
BOTTOM = 'bottom'

# Common options used to construct markers.
options =
  persistent: false
  invalidate: 'never'

# Private: ConflictParser discovers git conflict markers in a corpus of text and constructs Conflict
# instances that mark the correct lines.
#
parseConflict = (state, editor, row) ->
  previousSide = null

  d = (x) -> console.log "#{x} - #{editor.lineTextForBufferRow row}"

  # Mark and construct a Side that begins with a banner and description as its first line.
  markHeaderSide = (position, sideKlass) ->
    sideRowStart = row
    description = sideDescription()
    advanceToBoundary()
    sideRowEnd = row

    bannerMarker = editor.markBufferRange([[sideRowStart, 0], [sideRowStart + 1, 0]], options)
    previousSide.followingMarker = bannerMarker if previousSide?

    textRange = [[sideRowStart + 1, 0], [sideRowEnd, 0]]
    textMarker = editor.markBufferRange(textRange, options)
    text = editor.getTextInBufferRange(textRange)

    previousSide = new sideKlass(text, description, textMarker, bannerMarker, position)

  # Mark and construct a Side with a banner and description as its last line.
  markFooterSide = (position, sideKlass) ->
    sideRowStart = row
    advanceToBoundary()
    description = sideDescription()
    row += 1 # Advance past the boundary line.
    sideRowEnd = row

    textRange = [[sideRowStart, 0], [sideRowEnd - 1, 0]]
    textMarker = editor.markBufferRange(textRange, options)
    text = editor.getTextInBufferRange(textRange)

    bannerMarker = editor.markBufferRange([[sideRowEnd - 1, 0], [sideRowEnd, 0]], options)
    previousSide.followingMarker = bannerMarker if previousSide?

    previousSide = new sideKlass(text, description, textMarker, bannerMarker, position)
    previousSide.followingMarker = bannerMarker
    previousSide

  maybeMarkBase = -> if isAtSeparator() then null else markHeaderSide(BASE, BaseSide)

  markSeparator = ->
    sepRowStart = row
    row += 1
    sepRowEnd = row

    marker = editor.markBufferRange([[sepRowStart, 0], [sepRowEnd, 0]], options)
    previousSide.followingMarker = marker
    previousSide = new Navigator(marker)

  sideDescription = -> editor.lineTextForBufferRow(row).match(/^[<|>]{7} (.*)$/)[1]

  isAtBoundary = -> /^[<|=>]{7}/.test editor.lineTextForBufferRow(row)

  isAtSeparator = -> /^={7}$/.test editor.lineTextForBufferRow(row)

  advanceToBoundary = ->
    row += 1
    until isAtBoundary()
      row += 1

  if state.isRebase
    theirs = markHeaderSide(TOP, TheirSide)
    base = maybeMarkBase()
    nav = markSeparator()
    ours = markFooterSide(BOTTOM, OurSide)
  else
    ours = markHeaderSide(TOP, OurSide)
    base = maybeMarkBase()
    nav = markSeparator()
    theirs = markFooterSide(BOTTOM, TheirSide)

  conflict = new Conflict(ours, theirs, base, nav, state)

  return { conflict: conflict, endRow: row }

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
    conflicts = []
    lastRow = -1

    editor.getBuffer().scan CONFLICT_START_REGEX, (m) ->
      conflictStartRow = m.range.start.row
      return if conflictStartRow < lastRow

      result = parseConflict state, editor, conflictStartRow
      result.conflict.navigator.linkToPrevious conflicts[conflicts.length - 1] if conflicts.length > 0
      conflicts.push result.conflict
      lastRow = result.endRow

    conflicts

module.exports =
  Conflict: Conflict
