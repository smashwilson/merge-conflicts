'use babel'

import {Emitter} from 'atom'
import _ from 'underscore-plus'

import {Side, OurSide, TheirSide, BaseSide} from './side'
import {Navigator} from './navigator'

// Public: Model an individual conflict parsed from git's automatic conflict resolution output.
export class Conflict {

  /*
   * Private: Initialize a new Conflict with its constituent Sides, Navigator, and the MergeState
   * it belongs to.
   *
   * ours [Side] the lines of this conflict that the current user contributed (by our best guess).
   * theirs [Side] the lines of this conflict that another contributor created.
   * base [Side] the lines of merge base of this conflict. Optional.
   * navigator [Navigator] maintains references to surrounding Conflicts in the original file.
   * state [MergeState] repository-wide information about the current merge.
   */
  constructor (ours, theirs, base, navigator, merge) {
    this.ours = ours
    this.theirs = theirs
    this.base = base
    this.navigator = navigator
    this.merge = merge

    this.emitter = new Emitter()

    // Populate back-references
    this.ours.conflict = this
    this.theirs.conflict = this
    if (this.base) {
      this.base.conflict = this
    }
    this.navigator.conflict = this

    // Begin unresolved
    this.resolution = null
  }

  /*
   * Public: Has this conflict been resolved in any way?
   *
   * Return [Boolean]
   */
  isResolved() {
    return this.resolution !== null
  }

  /*
   * Public: Attach an event handler to be notified when this conflict is resolved.
   *
   * callback [Function]
   */
  onDidResolveConflict (callback) {
    return this.emitter.on('resolve-conflict', callback)
  }

  /*
   * Public: Specify which Side is to be kept. Note that either side may have been modified by the
   * user prior to resolution. Notify any subscribers.
   *
   * side [Side] our changes or their changes.
   */
  resolveAs (side) {
    this.resolution = side
    this.emitter.emit('resolve-conflict')
  }

  /*
   * Public: Locate the position that the editor should scroll to in order to make this conflict
   * visible.
   *
   * Return [Point] buffer coordinates
   */
  scrollTarget () {
    return this.ours.marker.getTailBufferPosition()
  }

  /*
   * Public: Audit all Marker instances owned by subobjects within this Conflict.
   *
   * Return [Array<Marker>]
   */
  markers () {
    const ms = [this.ours.markers(), this.theirs.markers(), this.navigator.markers()]
    if (this.baseSide) {
      ms.push(this.baseSide.markers())
    }
    return _.flatten(ms, true)
  }

  /*
   * Public: Console-friendly identification of this conflict.
   *
   * Return [String] that distinguishes this conflict from others.
   */
  toString () {
    return `[conflict: ${this.ours} ${this.theirs}]`
  }

  /*
   * Public: Parse any conflict markers in a TextEditor's buffer and return a Conflict that contains
   * markers corresponding to each.
   *
   * merge [MergeState] Repository-wide state of the merge.
   * editor [TextEditor] The editor to search.
   * return [Array<Conflict>] A (possibly empty) collection of parsed Conflicts.
   */
  static all (merge, editor) {
    const conflicts = []
    let lastRow = -1

    editor.getBuffer().scan(CONFLICT_START_REGEX, (m) => {
      conflictStartRow = m.range.start.row
      if (conflictStartRow < lastRow) {
        // Match within an already-parsed conflict.
        return
      }

      const visitor = new ConflictVisitor(merge, editor)

      try {
        lastRow = parseConflict(merge, editor, conflictStartRow, visitor)
        const conflict = visitor.conflict()

        if (conflicts.length > 0) {
          conflict.navigator.linkToPrevious(conflicts[conflicts.length - 1])
        }
        conflicts.push(conflict)
      } catch (e) {
        if (!e.parserState) throw e

        if (!atom.inSpecMode()) {
          console.error(`Unable to parse conflict: ${e.message}\n${e.stack}`)
        }
      }
    })

    return conflicts
  }
}

// Regular expression that matches the beginning of a potential conflict.
const CONFLICT_START_REGEX = /^<{7} (.+)\r?\n/g

// Side positions.
const TOP = 'top'
const BASE = 'base'
const BOTTOM = 'bottom'

// Options used to initialize markers.
const options = {
  persistent: false,
  invalidate: 'never'
}

/*
 * Private: conflict parser visitor that ignores all events.
 */
class NoopVisitor {

  visitOurSide (position, bannerRow, textRowStart, textRowEnd) { }

  visitBaseSide (position, bannerRow, textRowStart, textRowEnd) { }

  visitSeparator (sepRowStart, sepRowEnd) { }

  visitTheirSide (position, bannerRow, textRowStart, textRowEnd) { }

}

/*
 * Private: conflict parser visitor that marks each buffer range and assembles a Conflict from the
 * pieces.
 */
class ConflictVisitor {

  /*
   * merge - [MergeState] passed to each instantiated Side.
   * editor - [TextEditor] displaying the conflicting text.
   */
  constructor (merge, editor) {
    this.merge = merge
    this.editor = editor
    this.previousSide = null

    this.ourSide = null
    this.baseSide = null
    this.navigator = null
  }

  /*
   * position - [String] one of TOP or BOTTOM.
   * bannerRow - [Integer] of the buffer row that contains our side's banner.
   * textRowStart - [Integer] of the first buffer row that contain this side's text.
   * textRowEnd - [Integer] of the first buffer row beyond the extend of this side's text.
   */
  visitOurSide (position, bannerRow, textRowStart, textRowEnd) {
    this.ourSide = this.markSide(position, OurSide, bannerRow, textRowStart, textRowEnd)
  }

  /*
   * bannerRow - [Integer] the buffer row that contains our side's banner.
   * textRowStart - [Integer] first buffer row that contain this side's text.
   * textRowEnd - [Integer] first buffer row beyond the extend of this side's text.
   */
  visitBaseSide (bannerRow, textRowStart, textRowEnd) {
    this.baseSide = this.markSide(BASE, BaseSide, bannerRow, textRowStart, textRowEnd)
  }

  /*
   * sepRowStart - [Integer] buffer row that contains the "=======" separator.
   * sepRowEnd - [Integer] the buffer row after the separator.
   */
  visitSeparator (sepRowStart, sepRowEnd) {
    const marker = this.editor.markBufferRange([[sepRowStart, 0], [sepRowEnd, 0]], options)
    this.previousSide.followingMarker = marker

    this.navigator = new Navigator(marker)
    this.previousSide = this.navigator
  }

  /*
   * position - [String] Always BASE; accepted for consistency.
   * bannerRow - [Integer] the buffer row that contains our side's banner.
   * textRowStart - [Integer] first buffer row that contain this side's text.
   * textRowEnd - [Integer] first buffer row beyond the extend of this side's text.
   */
  visitTheirSide (position, bannerRow, textRowStart, textRowEnd) {
    this.theirSide = this.markSide(position, TheirSide, bannerRow, textRowStart, textRowEnd)
  }

  markSide (position, sideKlass, bannerRow, textRowStart, textRowEnd) {
    const description = this.sideDescription(bannerRow)

    const bannerMarker = this.editor.markBufferRange([[bannerRow, 0], [bannerRow + 1, 0]], options)

    if (this.previousSide) {
      this.previousSide.followingMarker = bannerMarker
    }

    const textRange = [[textRowStart, 0], [textRowEnd, 0]]
    const textMarker = this.editor.markBufferRange(textRange, options)
    const text = this.editor.getTextInBufferRange(textRange)

    const side = new sideKlass(text, description, textMarker, bannerMarker, position)
    this.previousSide = side
    return side
  }

  /*
   * Parse the banner description for the current side from a banner row.
   */
  sideDescription (bannerRow) {
    return this.editor.lineTextForBufferRow(bannerRow).match(/^[<|>]{7} (.*)$/)[1]
  }

  conflict () {
    this.previousSide.followingMarker = this.previousSide.refBannerMarker

    return new Conflict(this.ourSide, this.theirSide, this.baseSide, this.navigator, this.merge)
  }

}

/*
 * Private: parseConflict discovers git conflict markers in a corpus of text and constructs Conflict
 * instances that mark the correct lines.
 *
 * Returns [Integer] the buffer row after the final <<<<<< boundary.
 */
const parseConflict = function (merge, editor, row, visitor) {
  let lastBoundary = null

  // Visit a side that begins with a banner and description as its first line.
  const visitHeaderSide = (position, visitMethod) => {
    const sideRowStart = row
    row += 1
    advanceToBoundary('|=')
    const sideRowEnd = row

    visitor[visitMethod](position, sideRowStart, sideRowStart + 1, sideRowEnd)
  }

  // Visit the base side from diff3 output, if one is present, then visit the separator.
  const visitBaseAndSeparator = () => {
    if (lastBoundary === '|') {
      visitBaseSide()
    }

    visitSeparator()
  }

  // Visit a base side from diff3 output.
  const visitBaseSide = () => {
    const sideRowStart = row
    row += 1

    let b = advanceToBoundary('<=')
    while (b === '<') {
      // Embedded recursive conflict within a base side, caused by a criss-cross merge.
      // Advance beyond it without marking anything.
      row = parseConflict(merge, editor, row, new NoopVisitor())
      b = advanceToBoundary('<=')
    }

    const sideRowEnd = row

    visitor.visitBaseSide(sideRowStart, sideRowStart + 1, sideRowEnd)
  }

  // Visit a "========" separator.
  const visitSeparator = () => {
    const sepRowStart = row
    row += 1
    const sepRowEnd = row

    visitor.visitSeparator(sepRowStart, sepRowEnd)
  }

  // Vidie a side with a banner and description as its last line.
  const visitFooterSide = (position, visitMethod) => {
    const sideRowStart = row
    const b = advanceToBoundary('>')
    row += 1
    sideRowEnd = row

    visitor[visitMethod](position, sideRowEnd - 1, sideRowStart, sideRowEnd - 1)
  }

  // Determine if the current row is a side boundary.
  //
  // boundaryKinds - [String] any combination of <, |, =, or > to limit the kinds of boundary
  //   detected.
  //
  // Returns the matching boundaryKinds character, or `null` if none match.
  const isAtBoundary = (boundaryKinds = '<|=>') => {
    const line = editor.lineTextForBufferRow(row)
    for (b of boundaryKinds) {
      if (line.startsWith(b.repeat(7))) {
        return b
      }
    }
    return null
  }

  // Increment the current row until the current line matches one of the provided boundary kinds,
  // or until there are no more lines in the editor.
  //
  // boundaryKinds - [String] any combination of <, |, =, or > to limit the kinds of boundaries
  //   that halt the progression.
  //
  // Returns the matching boundaryKinds character, or 'null' if there are no matches to the end of
  // the editor.
  const advanceToBoundary = (boundaryKinds = '<|=>') => {
    let b = isAtBoundary(boundaryKinds)
    while (b === null) {
      row += 1
      if (row > editor.getLastBufferRow()) {
        const e = new Error('Unterminated conflict side')
        e.parserState = true
        throw e
      }
      b = isAtBoundary(boundaryKinds)
    }

    lastBoundary = b
    return b
  }

  if (!merge.isRebase) {
    visitHeaderSide(TOP, 'visitOurSide')
    visitBaseAndSeparator()
    visitFooterSide(BOTTOM, 'visitTheirSide')
  } else {
    visitHeaderSide(TOP, 'visitTheirSide')
    visitBaseAndSeparator()
    visitFooterSide(BOTTOM, 'visitOurSide')
  }

  return row
}
