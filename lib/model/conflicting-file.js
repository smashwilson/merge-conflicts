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
    for (let conflict of this.conflicts) {
      conflict.destroy()
    }
  }

  installInEditor (editor) {
    this.conflicts = Conflict.allInEditor(editor, this.merge.isRebase)
    this.conflicts.forEach((c) => c.belongsToConflictingFile(this))
  }

}
