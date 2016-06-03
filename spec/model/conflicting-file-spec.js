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

  describe('safePath', () => {
    it('preserves lowercase letters and numbers', () => {
      cf = makeConflictingFile().path('aaa123').build()
      expect(cf.safePath()).toBe('aaa123')
    })

    it('escapes non-alphanumeric symbols', () => {
      cf = makeConflictingFile().path('some/path.c').build()
      expect(cf.safePath()).toBe('some_002fpath_002ec')
    })

    it('escapes capital letters', () => {
      cf = makeConflictingFile().path('aBcDeF').build()
      expect(cf.safePath()).toBe('a__bc__de__f')
    })

    it('escapes an actual underscore', () => {
      cf = makeConflictingFile().path('aaa_bbb').build()
      expect(cf.safePath()).toBe('aaa_005fbbb')
    })
  })

  afterEach(() => {
    if (cf) cf.destroy()
  })
})
