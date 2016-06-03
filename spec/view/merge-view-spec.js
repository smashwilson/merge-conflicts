'use babel'
/* global describe it beforeEach waitsForPromise runs expect */

import {getScheduler} from 'etch'

import MergeView from '../../lib/view/merge-view'

import {makeMockVCS, makeMerge, makeConflict} from '../builders'

describe('MergeView', () => {
  let merge, conflict
  let vcs, view, root

  beforeEach(() => {
    vcs = makeMockVCS()
      .addConflict({ path: '/root/lib/aaa.c', relativePath: 'lib/aaa.c', message: 'both modified' })
      .addConflict({ path: '/root/lib/bbb.c', relativePath: 'lib/bbb.c', message: 'both modified' })
      .addConflict({ path: '/root/lib/ccc.c', relativePath: 'lib/ccc.c', message: 'both modified' })

    merge = makeMerge().vcs(vcs).build()

    waitsForPromise(() => merge.reread())

    runs(() => {
      conflict = makeConflict().omitParent().build()
      const other = makeConflict().omitParent().build()

      merge.conflictingFiles.get('/root/lib/bbb.c').installConflicts([conflict, other])

      view = new MergeView(merge)
      root = view.element
    })
  })

  describe('conflict resolution progress', () => {
    it('starts at zero', () => {
      const progress = root.querySelector('li.lib_002fbbb_002ec progress')
      expect(progress.value).toBe(0)
      expect(progress.max).toBe(2)
    })

    it('advances when a conflict is resolved', () => {
      conflict.ours.resolve()

      waitsForPromise(() => getScheduler().getNextUpdatePromise())

      runs(() => {
        const progress = root.querySelector('li.lib_002fbbb_002ec progress')
        expect(progress.value).toBe(1)
        expect(progress.max).toBe(2)
      })
    })
  })
})
