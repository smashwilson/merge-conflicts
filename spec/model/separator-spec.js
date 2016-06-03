'use babel'
/* globals describe it expect */

import {makeSeparator} from '../builders'

describe('Separator', () => {
  it('references a Switchboard', () => {
    const separator = makeSeparator().build()

    expect(separator.switchboard()).toBe(separator.conflict.conflictingFile.merge.switchboard())
  })
})
