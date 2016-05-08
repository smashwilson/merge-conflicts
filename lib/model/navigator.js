'use babel'

export default class Navigator {

  constructor () {
    this.conflict = null
  }

  belongsToConflict (conflict) {
    this.conflict = conflict
  }

  switchboard () {
    return this.conflict.switchboard()
  }

  destroy () {
    // No-op
  }

}
