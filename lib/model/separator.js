'use babel'

export default class Separator {

  constructor (bannerMarker) {
    this.conflict = null
    this.bannerMarker = bannerMarker
  }

  belongsToConflict (conflict) {
    this.conflict = conflict
  }

  switchboard () {
    return this.conflict.switchboard()
  }

  destroy () {
    this.bannerMarker.destroy()
  }

  static markInEditor (editor, sepRow) {
    const bannerMarker = editor.markBufferRange([[sepRow, 0], [sepRow + 1, 0]], {
      persistent: false,
      invalidate: 'never'
    })
    return new Separator(bannerMarker)
  }

}
