'use babel'

import Conflict from './conflict'

export default class ConflictingFile {

  constructor (path, message) {
    this.merge = null

    this.path = path
    this.message = message

    this.conflicts = null
  }

  belongsToMerge (merge) {
    this.merge = merge
  }

  switchboard () {
    return this.merge.switchboard()
  }

  destroy () {
    if (this.conflicts) {
      for (let conflict of this.conflicts) {
        conflict.destroy()
      }
    }
  }

  totalConflictCount () {
    if (!this.conflicts) return 1

    return this.conflicts.length
  }

  resolvedConflictCount () {
    if (!this.conflicts) return 0

    let count = 0
    for (let c of this.conflicts) {
      if (c.isResolved()) count++
    }
    return count
  }

  installInEditor (editor) {
    this.conflicts = Conflict.allInEditor(editor, this.merge.isRebase)
    for (let conflict of this.conflicts) {
      conflict.belongsToConflictingFile(this)
    }
  }

}
