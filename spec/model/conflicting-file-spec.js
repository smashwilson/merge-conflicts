'use babel'
/* global describe it expect beforeEach afterEach */

import {makeConflictingFile, makeConflict} from '../builders'

describe('ConflictingFile', () => {
  let cf

  describe('uninstalled', () => {
    beforeEach(() => cf = makeConflictingFile().build())

    it('reports 0 resolved conflicts', () => {
      expect(cf.resolvedConflictCount()).toBe(0)
    })

    it('reports positive total conflicts', () => {
      expect(cf.totalConflictCount()).toBeGreaterThan(0)
    })
  })

  describe('installed', () => {
    beforeEach(() => {
      cf = makeConflictingFile().build()

      const cs = [
        makeConflict().build(),
        makeConflict().build(),
        makeConflict().build()
      ]
      cf.installConflicts(cs)

      cs[0].ours.resolve()
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
