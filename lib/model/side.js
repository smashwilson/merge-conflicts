'use babel'

export default class Side {

  constructor (kind, position, description, originalText, bannerMarker, textMarker) {
    this.kind = kind
    this.position = position
    this.description = description

    this.originalText = originalText

    this.bannerMarker = bannerMarker
    this.textMarker = textMarker

    this.isDirty = false
  }

  belongsToConflict (conflict) {
    this.conflict = conflict
  }

  switchboard () {
    return this.conflict.switchboard()
  }

  destroy () {
    this.bannerMarker.destroy()
    this.textMarker.destroy()
  }

  resolve () {
    this.conflict.resolveAs(this)
  }

  wasChosen () {
    return this.conflict.resolution === this
  }

  toString () {
    let text = this.originalText.replace(/[\n\r]/, ' ')
    if (text.length > 20) {
      text = text.slice(0, 17) + '...'
    }

    const dirtyMark = this.isDirty ? 'dirty' : ''
    const chosenMark = this.wasChosen() ? 'chosen' : ''

    return `[Side ${this.kind} ${this.ref}:${text}:${dirtyMark}${chosenMark}]`
  }

  static markInEditor (editor, kind, position, bannerRow, textRowStart, textRowEnd) {
    const description = sideDescription(editor, bannerRow)

    const bannerMarker = editor.markBufferRange([[bannerRow, 0], [bannerRow + 1, 0]], {
      persistent: false,
      invalidate: 'never'
    })

    const textRange = [[textRowStart, 0], [textRowEnd, 0]]
    const textMarker = editor.markBufferRange(textRange, {
      persistent: false,
      invalidate: 'never'
    })
    const text = editor.getTextInBufferRange(textRange)

    return new Side(kind, position, description, text, bannerMarker, textMarker)
  }

}

export const Kinds = Object.freeze({
  OURS: 'ours',
  THEIRS: 'theirs',
  BASE: 'base'
})

export const Positions = Object.freeze({
  TOP: 'top',
  MIDDLE: 'middle',
  BOTTOM: 'bottom'
})

function sideDescription (editor, bannerRow) {
  return editor.lineTextForBufferRow(bannerRow).match(/^[<|>]{7} (.*)$/)[1]
}
