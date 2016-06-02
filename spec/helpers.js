'use babel'
/* global atom */

import path from 'path'

export function openFixture (fixturePath) {
  const fullPath = path.join(__dirname, 'fixtures', fixturePath)
  return atom.workspace.open(fullPath)
}
