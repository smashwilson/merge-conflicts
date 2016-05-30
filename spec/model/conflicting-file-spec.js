'use babel'
/* global describe it expect beforeEach afterEach */

import ConflictingFile from '../../lib/model/conflicting-file'
import {createConflict, createMerge} from '../helpers'

describe('ConflictingFile', () => {
  let cf

  describe('uninstalled', () => {
    beforeEach(() => {
      cf = new ConflictingFile('some/file.js', 'both modified')
      cf.belongsToMerge(createMerge())
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
      cf.belongsToMerge(createMerge())

      cf.conflicts = []
      for (let i = 0; i < 3; i++) {
        const c = createConflict()
        c.belongsToConflictingFile(cf)
        cf.conflicts.push(c)

        if (i === 0) {
          c.ours.resolve()
        }
      }
    })

    it('counts total conflicts', () => {
      expect(cf.totalConflictCount()).toBe(3)
    })

    it('counts resolved conflicts', () => {
      expect(cf.resolvedConflictCount()).toBe(1)
    })
  })

  afterEach(() => {
    if (cf) cf.destroy()
  })
})
