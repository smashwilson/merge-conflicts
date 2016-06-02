'use babel'

import Side, {Kinds, Positions} from '../lib/model/side'
import Conflict from '../lib/model/conflict'
import Separator from '../lib/model/separator'
import Navigator from '../lib/model/navigator'
import ConflictingFile from '../lib/model/conflicting-file'
import Merge from '../lib/model/merge'
import Switchboard from '../lib/model/switchboard'

class SideBuilder {
  constructor () {
    this._kind = Kinds.OURS
    this._position = Positions
    this._description = 'aaa111'
    this._originalText = 'original text'
    this._bannerMarker = new MockMarker()
    this._textMarker = new MockMarker()

    this._conflictBuilder = new ConflictBuilder()
    this._conflict = null
  }

  beTheirs () {
    this.kind(Kinds.THEIRS)
    this.position(Positions.BOTTOM)
    this.description('bbb222')
    this.originalText('their side text')
    return this
  }

  beBase () {
    this.kind(Kinds.BASE)
    this.position(Positions.MIDDLE)
    this.description('ccc333')
    this.originalText('base side text')
    return this
  }

  build () {
    const s = new Side(this._kind, this._position, this._description, this._originalText, this._bannerMarker, this._textMarker)

    if (!this._conflict) {
      this._conflict = this._conflictBuilder.build()
    }
    s.belongsToConflict(this._conflict)

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
  }

  build () {
    const s = new Separator(this._bannerMarker)

    if (!this._conflict) {
      this._conflict = this._conflictBuilder.build()
    }
    s.belongsToConflict(this._conflict)

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
  }

  build () {
    const n = new Navigator()

    if (!this._conflict) {
      this._conflict = this._conflictBuilder.build()
    }
    n.belongsToConflict(this._conflict)

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
  }

  beThreeWay () {
    this.base(makeSide().beBase().build())
    return this
  }

  build () {
    if (!this._ours) {
      this._ours = makeSide().conflict(true).build()
    }

    if (!this._theirs) {
      this._theirs = makeSide().beTheirs().conflict(true).build()
    }

    if (!this._separator) {
      this._separator = makeSeparator().conflict(true).build()
    }

    const c = new Conflict(this._ours, this._theirs, this._base, this._separator)

    if (!this._conflictingFile) {
      this._conflictingFile = this._conflictingFileBuilder.build()
    }
    c.belongsToConflictingFile(this._conflictingFile)

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
  }

  build () {
    const cf = new ConflictingFile(this._path, this._message)

    if (!this._merge) {
      this._merge = this._mergeBuilder.build()
    }
    cf.belongsToMerge(this._merge)

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

export class MockVCS {
  constructor () {
    this.conflicts = []
  }

  readConflicts () {
    return Promise.resolve(this.conflicts)
  }
}

export class MockMarker {
  constructor () {
    this.destroyed = false
  }

  destroy () {
    this.destroyed = true
  }
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
      let builder
      chain.forEach((link) => builder = builder[`_${link}Builder`])
      thunk(builder)
      return this
    }
  }

  parentChain.forEach((link, i) => {
    const withName = `with${link[0].toUpperCase()}${link.slice(1)}`

    builderPrototype[withName] = makeParentAccessor(parentChain.slice(i))
  })
}
