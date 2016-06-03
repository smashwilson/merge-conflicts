'use babel'
/* global describe it beforeEach waitsForPromise runs expect */

import Switchboard from '../../lib/model/switchboard'
import Merge from '../../lib/model/merge'

import {makeMerge, makeMockVCS} from '../builders'

describe('Merge', () => {
  let sb, merge

  beforeEach(() => sb = new Switchboard())

  it('is read from a VCS context', () => {
    const vcs = makeMockVCS()
      .addConflict({ path: '/root/lib/aaa.c', relativePath: 'lib/aaa.c', message: 'both modified' })
      .addConflict({ path: '/root/lib/bbb.c', relativePath: 'lib/bbb.c', message: 'both modified' })
      .addConflict({ path: '/root/lib/ccc.c', relativePath: 'lib/ccc.c', message: 'both modified' })

    waitsForPromise(() => Merge.read(sb, vcs).then((m) => (merge = m)))

    runs(() => {
      expect(merge.switchboard()).toBe(sb)
      expect(merge.vcs).toBe(vcs)
      expect(merge.conflictingFiles.get('/root/lib/aaa.c').path).toBe('lib/aaa.c')
      expect(merge.conflictingFiles.get('/root/lib/bbb.c').path).toBe('lib/bbb.c')
      expect(merge.conflictingFiles.get('/root/lib/ccc.c').path).toBe('lib/ccc.c')
      expect(merge.isRebase).toBe(false)
    })
  })

  it('reports non-emptiness', () => {
    const vcs = makeMockVCS()
      .addConflict({ path: '/root/lib/aaa.c', relativePath: 'lib/aaa.c', message: 'both modified' })
    merge = makeMerge().vcs(vcs).build()
    waitsForPromise(() => merge.reread())

    runs(() => {
      expect(merge.isEmpty()).toBe(false)
    })
  })

  it('reports emptiness', () => {
    const vcs = makeMockVCS()
    merge = makeMerge().vcs(vcs).build()
    waitsForPromise(() => merge.reread())

    runs(() => {
      expect(merge.isEmpty()).toBe(true)
    })
  })
})
