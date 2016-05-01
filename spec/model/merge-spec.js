'use babel'

import Switchboard from '../../lib/model/switchboard'
import Merge, {ConflictingFile} from '../../lib/model/merge'

describe('Merge', () => {
  it('is read from a VCS context', () => {
    const sb = new Switchboard()

    const fs = [
      new ConflictingFile('lib/aaa.c', 'both modified'),
      new ConflictingFile('lib/bbb.c', 'both modified'),
      new ConflictingFile('lib/ccc.c', 'both modified')
    ]

    const vcsContext = {
      isRebasing: () => false,
      readConflicts: () => Promise.resolve(fs)
    }

    waitsForPromise(() => Merge.read(sb, vcsContext).then((merge) => {
      expect(merge.switchboard).toBe(sb)
      expect(merge.vcsContext).toBe(vcsContext)
      expect(merge.files).toBe(fs)
      expect(merge.isRebase).toBe(false)
    }));
  })
})
