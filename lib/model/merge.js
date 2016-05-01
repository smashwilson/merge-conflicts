'use babel'

import {delegateSubscriptionMethodsTo, delegateBroadcastMethodsTo} from './switchboard'

/*
 * Representation of the state of an interrupted merge within a version control repository.
 */
export default class Merge {

  constructor (switchboard, files, vcsContext, isRebase) {
    this.switchboard = switchboard
    delegateSubscriptionMethodsTo(this, this.switchboard)
    delegateBroadcastMethodsTo(this, this.switchboard)

    this.files = files
    this.vcsContext = vcsContext
    this.isRebase = isRebase
  }

  conflictingPaths () {
    return this.files.map((conflict) => conflict.path)
  }

  isEmpty () {
    return this.files.length === 0
  }

  relativize (fullPath) {
    return this.vcsContext.workingDirectory.relativize(fullPath)
  }

  join (relativePath) {
    return this.vcsContext.joinPath(relativePath)
  }

  reread() {
    return this.vcsContext.readConflicts().then((files) => {
      this.files = files
      return this
    })
  }

  static read (switchboard, vcsContext) {
    const isRebasing = vcsContext.isRebasing()
    return vcsContext.readConflicts().then((entries) => {
      return new Merge(switchboard, entries, vcsContext, isRebasing)
    })
  }

}

export class ConflictingFile {

  constructor (path, message) {
    this.path = path
    this.message = message

    this.isReadyToStage = false
    this.isResolved = false

    this.totalConflictCount = 100
    this.resolvedConflictCount = 0
  }

  readyToResolve () {
    return this.resolvedConflictCount === this.totalConflictCount
  }

}
