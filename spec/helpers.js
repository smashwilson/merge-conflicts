'use babel'

import Switchboard from '../lib/model/switchboard'
import Merge from '../lib/model/merge'
import {Conflict} from '../lib/model/conflict'
import Side, {Kinds, Positions} from '../lib/model/side'
import Separator from '../lib/model/separator'

export function createConflict () {
  const ours = new Side(Kinds.OURS, Positions.TOP, 'aaa111', 'our side text', new MockMarker(), new MockMarker())
  const theirs = new Side(Kinds.THEIRS, Positions.BOTTOM, 'bbb222', 'their side text', new MockMarker(), new MockMarker())
  const separator = new Separator(new MockMarker())

  return new Conflict(ours, theirs, null, separator)
}

export function createMerge () {
  const switchboard = new Switchboard()
  const vcs = new MockVCS()

  return new Merge(switchboard, vcs, false)
}

class MockVCS {
  constructor () {
    this.conflicts = []
  }

  readConflicts () {
    return Promise.resolve(this.conflicts)
  }
}

class MockMarker {
  constructor () {
    this.destroyed = false
  }

  destroy () {
    this.destroyed = true
  }
}
