'use babel'
/* globals describe it expect */

import {makeSide} from '../builders'

describe('Side', () => {
  it('references a Switchboard', () => {
    const side = makeSide().build()

    expect(side.switchboard()).toBe(side.conflict.conflictingFile.merge.switchboard())
  })

  describe('resolution', () => {
    it('may be chosen as the resolution of a Conflict', () => {
      const side = makeSide().build()

      side.resolve()
      expect(side.conflict.resolution).toBe(side)
      expect(side.wasChosen()).toBe(true)
    })
  })
})
