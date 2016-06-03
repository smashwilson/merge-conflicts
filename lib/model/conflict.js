'use babel'
/* global atom */

import Side, {Kinds, Positions} from './side'
import Separator from './separator'
import Navigator from './navigator'

/*
 * Public: Model an individual conflict parsed from git's automatic conflict resolution output.
 */
export default class Conflict {

  /*
   * Private: Initialize a new Conflict with its constituent Sides, Navigator, and the ConflictingFile
   * it belongs to.
   *
   * conflictingFile [ConflictingFile] the file that contained the conflict markers.
   * ours [Side] owns the lines of this conflict that the current user contributed (by our best guess).
   * theirs [Side] owns the lines of this conflict that another contributor created.
   * base [Side] owns the lines of merge base of this conflict. Optional.
   * separator [Separator] owns the line from the conflict that occurs just before the final Side.
   */
  constructor (ours, theirs, base, separator) {
    this.conflictingFile = null
    this.navigator = null

    this.ours = ours
    this.theirs = theirs
    this.base = base
    this.separator = separator

    // Populate back-references
    this.ours.belongsToConflict(this)
    this.theirs.belongsToConflict(this)
    if (this.base) {
      this.base.belongsToConflict(this)
    }
    this.separator.belongsToConflict(this)

    // Begin unresolved
    this.resolution = null
  }

  belongsToConflictingFile (conflictingFile) {
    this.conflictingFile = conflictingFile
  }

  setNavigator (navigator) {
    this.navigator = navigator
    this.navigator.belongsToConflict(this)
  }

  switchboard () {
    return this.conflictingFile.switchboard()
  }

  destroy () {
    this.ours.destroy()
    this.theirs.destroy()
    this.separator.destroy()

    if (this.base) {
      this.base.destroy()
    }

    if (this.navigator) {
      this.navigator.destroy()
    }
  }

  /*
   * Public: Has this conflict been resolved in any way?
   *
   * Return [Boolean]
   */
  isResolved () {
    return this.resolution !== null
  }

  /*
   * Public: Specify which Side is to be kept. Note that either side may have been modified by the
   * user prior to resolution. Notify any subscribers.
   *
   * side [Side] our changes or their changes.
   */
  resolveAs (side) {
    this.resolution = side
    this.switchboard().didResolveConflict({ conflict: this })
  }

  /*
   * Public: Locate the position that the editor should scroll to in order to make this conflict
   * visible.
   *
   * Return [Point] buffer coordinates
   */
  scrollTarget () {
    const top = [this.ours, this.theirs].find((s) => s.position === Positions.TOP)
    return top.bannerMarker.getTailBufferPosition()
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
   * editor [TextEditor] The editor to search.
   * isRebasing [Boolean] True if the current Merge occurred during a rebase.
   * return [Array<Conflict>] A (possibly empty) collection of parsed Conflicts.
   */
  static allInEditor (editor, isRebasing) {
    const conflicts = []
    let lastRow = -1

    editor.getBuffer().scan(CONFLICT_START_REGEX, (m) => {
      const conflictStartRow = m.range.start.row
      if (conflictStartRow < lastRow) {
        // Match within an already-parsed conflict.
        return
      }

      const visitor = new ConflictVisitor(editor)

      try {
        lastRow = parseConflict(isRebasing, editor, conflictStartRow, visitor)
        const conflict = visitor.conflict()

        const navigator = new Navigator()
        conflict.setNavigator(navigator)
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
   * editor - [TextEditor] displaying the conflicting text.
   */
  constructor (editor) {
    this.editor = editor

    this.ourSide = null
    this.baseSide = null
    this.theirSide = null
    this.separator = null
  }

  /*
   * position - [String] one of TOP or BOTTOM.
   * bannerRow - [Integer] of the buffer row that contains our side's banner.
   * textRowStart - [Integer] of the first buffer row that contain this side's text.
   * textRowEnd - [Integer] of the first buffer row beyond the extend of this side's text.
   */
  visitOurSide (position, bannerRow, textRowStart, textRowEnd) {
    this.ourSide = Side.markInEditor(this.editor, Kinds.OURS, position, bannerRow, textRowStart, textRowEnd)
  }

  /*
   * bannerRow - [Integer] the buffer row that contains our side's banner.
   * textRowStart - [Integer] first buffer row that contain this side's text.
   * textRowEnd - [Integer] first buffer row beyond the extend of this side's text.
   */
  visitBaseSide (bannerRow, textRowStart, textRowEnd) {
    this.baseSide = Side.markInEditor(this.editor, Kinds.BASE, Positions.MIDDLE, bannerRow, textRowStart, textRowEnd)
  }

  /*
   * sepRow - [Integer] buffer row that contains the "=======" separator.
   */
  visitSeparator (sepRow) {
    this.separator = Separator.markInEditor(this.editor, sepRow)
  }

  /*
   * position - [String] Always BASE; accepted for consistency.
   * bannerRow - [Integer] the buffer row that contains our side's banner.
   * textRowStart - [Integer] first buffer row that contain this side's text.
   * textRowEnd - [Integer] first buffer row beyond the extend of this side's text.
   */
  visitTheirSide (position, bannerRow, textRowStart, textRowEnd) {
    this.theirSide = Side.markInEditor(this.editor, Kinds.THEIRS, position, bannerRow, textRowStart, textRowEnd)
  }

  conflict (conflictingFile) {
    return new Conflict(conflictingFile, this.ourSide, this.theirSide, this.baseSide, this.separator)
  }

}

/*
 * Private: parseConflict discovers git conflict markers in a corpus of text and constructs Conflict
 * instances that mark the correct lines.
 *
 * Returns [Integer] the buffer row after the final <<<<<< boundary.
 */
const parseConflict = function (isRebasing, editor, row, visitor) {
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
      row = parseConflict(isRebasing, editor, row, new NoopVisitor())
      b = advanceToBoundary('<=')
    }

    const sideRowEnd = row

    visitor.visitBaseSide(sideRowStart, sideRowStart + 1, sideRowEnd)
  }

  // Visit a "========" separator.
  const visitSeparator = () => {
    const sepRow = row
    row += 1

    visitor.visitSeparator(sepRow)
  }

  // Vidie a side with a banner and description as its last line.
  const visitFooterSide = (position, visitMethod) => {
    const sideRowStart = row
    advanceToBoundary('>')
    row += 1
    const sideRowEnd = row

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
    for (let b of boundaryKinds) {
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

  if (!isRebasing) {
    visitHeaderSide(Positions.TOP, 'visitOurSide')
    visitBaseAndSeparator()
    visitFooterSide(Positions.BOTTOM, 'visitTheirSide')
  } else {
    visitHeaderSide(Positions.TOP, 'visitTheirSide')
    visitBaseAndSeparator()
    visitFooterSide(Positions.BOTTOM, 'visitOurSide')
  }

  return row
}
