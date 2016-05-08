'use babel'

import {CompositeDisposable} from 'atom'
import ConflictingFile from './conflicting-file'

/*
 * Representation of the state of an interrupted merge within a version control repository.
 */
export default class Merge {

  constructor (switchboard, vcs, isRebase) {
    this.switchboard = switchboard

    this.conflictingFiles = null
    this.vcs = vcs
    this.isRebase = isRebase

    this.subs = new CompositeDisposable()
  }

  switchboard () {
    return this.switchboard
  }

  destroy () {
    if (this.conflictingFiles) {
      this.conflictingFiles.forEach((cf) => cf.destroy())
    }

    this.subs.dispose()
  }

  isEmpty () {
    return this.conflictingFiles.size === 0
  }

  reread () {
    if (!this.conflictingFiles) {
      this.conflictingFiles = new Map()
    }

    return this.vcs.readConflicts().then((entries) => {
      for (let entry of entries) {
        const relativePath = entry.path
        const fullPath = this.vcs.fullPathTo(relativePath)

        if (!this.conflictingFiles.has(fullPath)) {
          // New entry.
          const cf = new ConflictingFile(relativePath, entry.message)
          cf.belongsToMerge(this)
          this.conflictingFiles.set(fullPath, cf)
        }
      }

      return this
    })
  }

  installInWorkspace (workspace) {
    this.subs.add(workspace.observeTextEditors((editor) => {
      const fullPath = editor.getPath()
      const cf = this.conflictingFiles.get(fullPath)
      if (cf) {
        cf.installInEditor(editor)
      }
    }))
  }

  static read (switchboard, vcs) {
    return new Merge(switchboard, vcs, vcs.isRebasing()).reread()
  }

}
