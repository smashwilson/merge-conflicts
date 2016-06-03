'use babel'

import {Point} from 'atom'

import Side, {Kinds, Positions} from '../lib/model/side'
import Conflict from '../lib/model/conflict'
import Separator from '../lib/model/separator'
import Navigator from '../lib/model/navigator'
import ConflictingFile from '../lib/model/conflicting-file'
import Merge from '../lib/model/merge'
import Switchboard from '../lib/model/switchboard'

// Constructing interconnected model objects for test cases is awkward and verbose. These builders
// help by providing a way to construct fully initialized and valid model trees while only
// explicitly mentioning the model attributes that each case actually uses.
//
// This package exports a `makeXyz()` function corresponding to each model class. It returns a
// Builder instance populated with reasonable and valid default values for each model attribute,
// which may be selectively overridden by calling a literate method of the same name with the new
// value. Call the `build()` method to finalize the object's construction, including any required
// parent or child objects in the model tree.
//
// For example, to construct a Side:
//
// ```
// import {makeSide} from '../builders'
//
// const side = makeSide()
//   .description('custom')
//   .build()
// ```
//
// The Side object will have a description of "custom", valid placeholders for all other attributes,
// and will belong to a valid Conflict, ConflictingFile, and Merge, all populated with reasonable
// values.
//
// The structure of parent objects can be influenced by calling a `withXyz` method on the builder
// during construction. Each `withXyz` method calls a function object with the appropriate parent
// builder:
//
// ```
// const conflict = makeConflict()
//   .withMerge((mb) => mb.isRebase(true))
//   .build()
// ```

class SideBuilder {
  constructor () {
    this._kind = Kinds.OURS
    this._position = Positions.TOP
    this._description = 'aaa111'
    this._originalText = 'original text'
    this._bannerMarker = mockMarkerFrom(0, 1)
    this._textMarker = mockMarkerFrom(1, 2)

    this._conflictBuilder = new ConflictBuilder()
    this._conflict = null

    this._buildConflict = true
  }

  beTheirs () {
    this.kind(Kinds.THEIRS)
    this.position(Positions.BOTTOM)
    this.description('bbb222')
    this.originalText('their side text')
    this.bannerMarker(mockMarkerFrom(3, 4))
    this.textMarker(mockMarkerFrom(5, 6))
    return this
  }

  beBase () {
    this.kind(Kinds.BASE)
    this.position(Positions.MIDDLE)
    this.description('ccc333')
    this.originalText('base side text')
    this.bannerMarker(mockMarkerFrom(7, 8))
    this.textMarker(mockMarkerFrom(9, 10))
    return this
  }

  omitParent () {
    this._buildConflict = false
    return this
  }

  build () {
    const s = new Side(this._kind, this._position, this._description, this._originalText, this._bannerMarker, this._textMarker)

    if (!this._conflict && this._constructConflict) {
      const c = this._conflictBuilder
      if (this._kind === Kinds.OURS) c.ours(s)
      if (this._kind === Kinds.BASE) c.base(s)
      if (this._kind === Kinds.THEIRS) c.theirs(s)
      this._conflict = c.build()
    }
    if (this._conflict) s.belongsToConflict(this._conflict)

    return s
  }
}

makeLiterateSetters(SideBuilder.prototype,
  ['kind', 'position', 'description', 'originalText', 'bannerMarker', 'textMarker', 'conflict'])

makeParentHeirarchy(SideBuilder.prototype,
  ['conflict', 'conflictingFile', 'merge'])

export function makeSide () {
  return new SideBuilder()
}

class SeparatorBuilder {
  constructor () {
    this._bannerMarker = new MockMarker()

    this._conflictBuilder = new ConflictBuilder()
    this._conflict = null
    this._buildConflict = true
  }

  omitParent () {
    this._buildConflict = false
    return this
  }

  build () {
    const s = new Separator(this._bannerMarker)

    if (!this._conflict && this._buildConflict) {
      this._conflict = this._conflictBuilder.build()
    }
    if (this._conflict) s.belongsToConflict(this._conflict)

    return s
  }
}

makeLiterateSetters(SeparatorBuilder.prototype,
  ['bannerMarker', 'conflict'])

makeParentHeirarchy(SeparatorBuilder.prototype,
  ['conflict', 'conflictingFile', 'merge'])

export function makeSeparator () {
  return new SeparatorBuilder()
}

class NavigatorBuilder {
  constructor () {
    this._conflictBuilder = new ConflictBuilder()
    this._conflict = null
    this._buildConflict = true
  }

  omitParent () {
    this._buildConflict = false
    return this
  }

  build () {
    const n = new Navigator()

    if (!this._conflict && this._buildConflict) {
      this._conflict = this._conflictBuilder.build()
    }
    if (this._conflict) n.belongsToConflict(this._conflict)

    return n
  }
}

makeLiterateSetters(NavigatorBuilder.prototype,
  ['conflict'])

makeParentHeirarchy(NavigatorBuilder.prototype,
  ['conflict', 'conflictingFile', 'merge'])

export function makeNavigator () {
  return new NavigatorBuilder()
}

class ConflictBuilder {
  constructor () {
    this._ours = null
    this._base = null
    this._theirs = null
    this._separator = null

    this._conflictingFileBuilder = new ConflictingFileBuilder()
    this._conflictingFile = null
    this._buildConflictingFile = true
  }

  beThreeWay () {
    this.base(makeSide().beBase().omitParent().build())
    return this
  }

  omitParent () {
    this._buildConflictingFile = false
    return this
  }

  build () {
    if (!this._conflictingFile && this._buildConflictingFile) {
      this._conflictingFile = this._conflictingFileBuilder.build()
    }

    const isRebase = this._conflictingFile &&
      this._conflictingFile._merge &&
      this._conflictingFile._merge.isRebase

    if (!this._ours) {
      this._ours = makeSide()
        .omitParent()
        .position(isRebase ? Positions.BOTTOM : Positions.TOP)
        .build()
    }

    if (!this._theirs) {
      this._theirs = makeSide()
        .omitParent()
        .position(isRebase ? Positions.TOP : Positions.BOTTOM)
        .build()
    }

    if (!this._separator) {
      this._separator = makeSeparator().omitParent().build()
    }

    const c = new Conflict(this._ours, this._theirs, this._base, this._separator)

    if (this._conflictingFile) c.belongsToConflictingFile(this._conflictingFile)

    return c
  }
}

makeLiterateSetters(ConflictBuilder.prototype,
  ['ours', 'base', 'theirs', 'separator', 'conflictingFile'])

makeParentHeirarchy(ConflictBuilder.prototype,
  ['conflictingFile', 'merge'])

export function makeConflict () {
  return new ConflictBuilder()
}

class ConflictingFileBuilder {
  constructor () {
    this._path = 'directory/filename.ext'
    this._message = 'both modified'

    this._mergeBuilder = new MergeBuilder()
    this._merge = null
    this._buildMerge = true
  }

  omitParent () {
    this._buildMerge = false
    return this
  }

  build () {
    const cf = new ConflictingFile(this._path, this._message)

    if (!this._merge && this._buildMerge) {
      this._merge = this._mergeBuilder.build()
    }
    if (this._merge) cf.belongsToMerge(this._merge)

    return cf
  }
}

makeLiterateSetters(ConflictingFileBuilder.prototype,
  ['path', 'message', 'merge'])

makeParentHeirarchy(ConflictingFileBuilder.prototype,
  ['merge'])

export function makeConflictingFile () {
  return new ConflictingFileBuilder()
}

class MergeBuilder {
  constructor () {
    this._switchboard = new Switchboard()
    this._vcs = new MockVCS()
    this._isRebase = false
  }

  build () {
    return new Merge(this._switchboard, this._vcs, this._isRebase)
  }
}

makeLiterateSetters(MergeBuilder.prototype,
  ['switchboard', 'vcs', 'isRebase'])

export function makeMerge () {
  return new MergeBuilder()
}

class MockVCS {
  constructor () {
    this.conflicts = []
    this._isRebase = false
  }

  addConflict (entry) {
    this.conflicts.push(entry)
    return this
  }

  isRebasing () {
    return this._isRebase
  }

  readConflicts () {
    return Promise.resolve(this.conflicts)
  }
}

export function makeMockVCS () {
  return new MockVCS()
}

class MockMarker {
  constructor () {
    this.destroyed = false
    this._headBufferRow = 0
    this._tailBufferRow = 0
  }

  headRow (row) {
    this._headBufferRow = row
    return this
  }

  tailRow (row) {
    this._tailBufferRow = row
    return this
  }

  getHeadBufferPosition () {
    return new Point(this._headBufferRow, 0)
  }

  getTailBufferPosition () {
    return new Point(this._tailBufferRow, 0)
  }

  destroy () {
    this.destroyed = true
  }
}

export function makeMockMarker () {
  return new MockMarker()
}

export function mockMarkerFrom (headRow, tailRow) {
  return makeMockMarker().headRow(headRow).tailRow(tailRow)
}

function makeLiterateSetters (builderPrototype, attributeNames) {
  function makeSetter (attributeName) {
    return function (value) {
      this[`_${attributeName}`] = value
      return this
    }
  }

  attributeNames.forEach((attributeName) => {
    builderPrototype[attributeName] = makeSetter(attributeName)
  })
}

function makeParentHeirarchy (builderPrototype, parentChain) {
  const makeParentAccessor = (chain) => {
    return function (thunk) {
      let builder = this
      chain.forEach((link) => {
        builder = builder[`_${link}Builder`]
      })
      thunk(builder)
      return this
    }
  }

  for (let i = 0; i < parentChain.length; i++) {
    const parent = parentChain[i]
    const withName = `with${parent[0].toUpperCase()}${parent.slice(1)}`
    const chain = parentChain.slice(0, i + 1)

    builderPrototype[withName] = makeParentAccessor(chain)
  }
}
