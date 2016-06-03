'use babel'
/* globals describe it expect */

import {makeNavigator} from '../builders'

describe('Navigator', () => {
  it('references a Switchboard', () => {
    const navigator = makeNavigator().build()

    expect(navigator.switchboard()).toBe(navigator.conflict.conflictingFile.merge.switchboard())
  })
})
