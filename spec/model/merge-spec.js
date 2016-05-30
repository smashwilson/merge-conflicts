'use babel'
/* global describe it beforeEach waitsForPromise expect */

import Switchboard from '../../lib/model/switchboard'
import Merge from '../../lib/model/merge'

describe('Merge', () => {
  let sb, fs, vcs, merge

  beforeEach(() => {
    sb = new Switchboard()

    fs = [
      { path: '/root/lib/aaa.c', relativePath: 'lib/aaa.c', message: 'both modified' },
      { path: '/root/lib/bbb.c', relativePath: 'lib/bbb.c', message: 'both modified' },
      { path: '/root/lib/ccc.c', relativePath: 'lib/ccc.c', message: 'both modified' }
    ]

    vcs = {
      isRebasing: () => false,
      readConflicts: () => Promise.resolve(fs)
    }

    waitsForPromise(() => Merge.read(sb, vcs).then((m) => (merge = m)))
  })

  it('is read from a VCS context', () => {
    expect(merge._switchboard).toBe(sb)
    expect(merge.vcs).toBe(vcs)
    expect(merge.conflictingFiles.get('/root/lib/aaa.c').path).toBe(fs[0].relativePath)
    expect(merge.conflictingFiles.get('/root/lib/bbb.c').path).toBe(fs[1].relativePath)
    expect(merge.conflictingFiles.get('/root/lib/ccc.c').path).toBe(fs[2].relativePath)
    expect(merge.isRebase).toBe(false)
  })

  it('reports non-emptiness', () => {
    expect(merge.isEmpty()).toBe(false)
  })

  it('reports emptiness', () => {
    fs = []
    waitsForPromise(() => Merge.read(sb, vcs).then((other) => {
      expect(other.isEmpty()).toBe(true)
    }))
  })
})
