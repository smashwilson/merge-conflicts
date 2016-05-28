'use babel'
/* global describe it expect beforeEach afterEach */

import ConflictingFile from '../../lib/model/conflicting-file'

describe('ConflictingFile', () => {
  let cf

  describe('uninstalled', () => {
    beforeEach(() => {
      cf = new ConflictingFile('some/file.js', 'both modified')
    })

    it('reports 0 resolved conflicts', () => {
      expect(cf.resolvedConflictCount()).toBe(0)
    })

    it('reports positive total conflicts', () => {
      expect(cf.totalConflictCount()).toBeGreaterThan(0)
    })
  })

  describe('installed', () => {
    beforeEach(() => {
      cf = new ConflictingFile('some/file.js', 'both modified')
    })

    it('counts total conflicts')
    it('counts resolved conflicts')
  })

  afterEach(() => {
    if (cf) cf.destroy()
  })
})
