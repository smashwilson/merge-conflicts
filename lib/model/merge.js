'use babel'

import {CompositeDisposable} from 'atom'
import ConflictingFile from './conflicting-file'

/*
 * Representation of the state of an interrupted merge within a version control repository.
 */
export default class Merge {

  constructor (switchboard, vcs, isRebase) {
    this._switchboard = switchboard

    this.conflictingFiles = null
    this.vcs = vcs
    this.isRebase = isRebase

    this.subs = new CompositeDisposable()
  }

  switchboard () {
    return this._switchboard
  }

  destroy () {
    if (this.conflictingFiles) {
      for (let cf of this.conflictingFiles) {
        cf.destroy()
      }
    }

    this.subs.dispose()
  }

  mapConflictingFiles (fn) {
    const r = []
    for (let cf of this.conflictingFiles.values()) {
      r.push(fn(cf))
    }
    return r
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
        if (!this.conflictingFiles.has(entry.path)) {
          // New entry.
          const cf = new ConflictingFile(entry.relativePath, entry.message)
          cf.belongsToMerge(this)
          this.conflictingFiles.set(entry.path, cf)
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
