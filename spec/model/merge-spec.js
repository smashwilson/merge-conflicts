'use babel'

import Switchboard from '../../lib/model/switchboard'
import Merge, {ConflictingFile} from '../../lib/model/merge'

describe('Merge', () => {
  let sb, fs, vcsContext, merge

  beforeEach(() => {
    sb = new Switchboard()

    fs = [
      new ConflictingFile('lib/aaa.c', 'both modified'),
      new ConflictingFile('lib/bbb.c', 'both modified'),
      new ConflictingFile('lib/ccc.c', 'both modified')
    ]

    vcsContext = {
      isRebasing: () => false,
      readConflicts: () => Promise.resolve(fs)
    }

    waitsForPromise(() => Merge.read(sb, vcsContext).then((m) => merge = m))
  })

  it('is read from a VCS context', () => {
    expect(merge.switchboard).toBe(sb)
    expect(merge.vcsContext).toBe(vcsContext)
    expect(merge.files).toBe(fs)
    expect(merge.isRebase).toBe(false)
  })

  it('enumerates conflicting paths', () => {
    const ps = merge.conflictingPaths()
    expect(ps).toEqual(['lib/aaa.c', 'lib/bbb.c', 'lib/ccc.c'])
  })

  it('reports non-emptiness', () => {
    expect(merge.isEmpty()).toBe(false)
  })

  it('reports emptiness', () => {
    fs = []
    waitsForPromise(() => Merge.read(sb, vcsContext).then((other) => {
      expect(other.isEmpty()).toBe(true)
    }))
  })
})
