'use babel'
/* global describe it expect beforeEach afterEach waitsForPromise runs */

import {CompositeDisposable} from 'atom'

import Conflict from '../../lib/model/conflict'
import {Positions} from '../../lib/model/side'

import {makeConflict} from '../builders'
import {openFixture, rowRangeFrom} from '../helpers'

describe('Conflict', () => {
  let conflict, subs

  beforeEach(() => subs = new CompositeDisposable())

  describe('resolution', () => {
    beforeEach(() => conflict = makeConflict().build())

    it('begins unresolved', () => {
      expect(conflict.isResolved()).toBe(false)
    })

    it('emits didResolveConflict', () => {
      let capture
      subs.add(conflict.switchboard().onDidResolveConflict(({conflict}) => capture = conflict))

      conflict.ours.resolve()

      expect(capture).toBe(conflict)
    })

    it('recognizes its resolution', () => {
      conflict.theirs.resolve()

      expect(conflict.isResolved()).toBe(true)
    })
  })

  describe('scroll target', () => {
    it('scrolls to Ours for merges', () => {
      conflict = makeConflict().build()

      const ourTarget = conflict.ours.bannerMarker.getTailBufferPosition()
      expect(conflict.scrollTarget()).toEqual(ourTarget)
    })

    it('scrolls to Theirs for rebases', () => {
      conflict = makeConflict()
        .withMerge((m) => m.isRebase(true))
        .build()

      const theirTarget = conflict.theirs.bannerMarker.getTailBufferPosition()
      expect(conflict.scrollTarget()).toEqual(theirTarget)
    })
  })

  describe('parsing', () => {
    let conflicts

    function useFixture (fixtureName, rebase) {
      waitsForPromise(() => openFixture(fixtureName)
        .then((editor) => Conflict.allInEditor(editor, rebase))
        .then((cs) => {
          conflicts = cs
          if (conflicts.length > 0) conflict = conflicts[0]
        }))
    }

    describe('single two-way diff', () => {
      beforeEach(() => useFixture('single-2way-diff.txt'))

      it('finds the conflict text', () => {
        expect(rowRangeFrom(conflict.ours.textMarker)).toEqual([1, 2])
        expect(conflict.ours.description).toBe('HEAD')
        expect(conflict.ours.originalText).toBe('These are my changes\n')

        expect(rowRangeFrom(conflict.theirs.textMarker)).toEqual([3, 4])
        expect(conflict.theirs.description).toBe('master')
        expect(conflict.theirs.originalText).toBe('These are your changes\n')
      })

      it('finds the ref banners', () => {
        expect(rowRangeFrom(conflict.ours.bannerMarker)).toEqual([0, 1])
        expect(rowRangeFrom(conflict.theirs.bannerMarker)).toEqual([4, 5])
      })

      it('finds the separator', () => {
        expect(rowRangeFrom(conflict.separator.bannerMarker)).toEqual([2, 3])
      })

      it('marks "ours" as the top and "theirs" as the bottom', () => {
        expect(conflict.ours.position).toBe(Positions.TOP)
        expect(conflict.theirs.position).toBe(Positions.BOTTOM)
      })

      it('does not have a base side', () => {
        expect(conflict.base).toBeNull()
      })
    })

    describe('single three-way diff', () => {
      beforeEach(() => useFixture('single-3way-diff.txt'))

      it('identifies the correct rows', () => {
        expect(rowRangeFrom(conflict.ours.textMarker)).toEqual([1, 2])
        expect(conflict.ours.description).toBe('HEAD')
        expect(conflict.ours.originalText).toBe('These are my changes\n')

        expect(rowRangeFrom(conflict.base.textMarker)).toEqual([3, 4])
        expect(conflict.base.description).toBe('merged common ancestors')
        expect(conflict.base.originalText).toBe('These are original texts\n')

        expect(rowRangeFrom(conflict.theirs.textMarker)).toEqual([5, 6])
        expect(conflict.theirs.description).toBe('master')
        expect(conflict.theirs.originalText).toBe('These are your changes\n')
      })

      it('finds all three banners', () => {
        expect(rowRangeFrom(conflict.ours.bannerMarker)).toEqual([0, 1])
        expect(rowRangeFrom(conflict.base.bannerMarker)).toEqual([2, 3])
        expect(rowRangeFrom(conflict.theirs.bannerMarker)).toEqual([6, 7])
      })

      it('finds the separator', () => {
        expect(rowRangeFrom(conflict.separator.bannerMarker)).toEqual([4, 5])
      })

      it('marks side positions correctly', () => {
        expect(conflict.ours.position).toBe(Positions.TOP)
        expect(conflict.base.position).toBe(Positions.MIDDLE)
        expect(conflict.theirs.position).toBe(Positions.BOTTOM)
      })
    })

    describe('complex three-way diff', () => {
      beforeEach(() => useFixture('single-3way-diff-complex.txt'))

      it('identifies the correct rows for complex three-way diffs', () => {
        expect(rowRangeFrom(conflict.ours.textMarker)).toEqual([1, 2])
        expect(conflict.ours.description).toBe('HEAD')
        expect(rowRangeFrom(conflict.base.textMarker)).toEqual([3, 18])
        expect(conflict.base.description).toBe('merged common ancestors')
        expect(rowRangeFrom(conflict.theirs.textMarker)).toEqual([19, 20])
        expect(conflict.theirs.description).toBe('master')
      })
    })

    describe('multiple two-way diffs', () => {
      beforeEach(() => useFixture('multi-2way-diff.txt'))

      it('finds all conflict markings', () => {
        expect(conflicts.length).toBe(2)

        expect(rowRangeFrom(conflicts[0].ours.textMarker)).toEqual([5, 7])
        expect(rowRangeFrom(conflicts[0].theirs.textMarker)).toEqual([8, 9])
        expect(rowRangeFrom(conflicts[1].ours.textMarker)).toEqual([14, 15])
        expect(rowRangeFrom(conflicts[1].theirs.textMarker)).toEqual([16, 17])
      })
    })

    describe('when rebasing', () => {
      beforeEach(() => useFixture('rebase-2way-diff.txt', true))

      it('swaps the lines for "ours" and "theirs"', () => {
        expect(rowRangeFrom(conflict.theirs.textMarker)).toEqual([3, 4])
        expect(rowRangeFrom(conflict.ours.textMarker)).toEqual([5, 6])
      })

      it('recognizes banner lines with commit shortlog messages', () => {
        expect(rowRangeFrom(conflict.theirs.bannerMarker)).toEqual([2, 3])
        expect(rowRangeFrom(conflict.ours.bannerMarker)).toEqual([6, 7])
      })

      it('marks "theirs" as the top and "ours" as the bottom', () => {
        expect(conflict.theirs.position).toBe(Positions.TOP)
        expect(conflict.ours.position).toBe(Positions.BOTTOM)
      })
    })

    describe('corrupted diff markers', () => {
      it('handles corrupted diff output', () => {
        useFixture('corrupted-2way-diff.txt')

        runs(() => {
          expect(conflicts.length).toBe(0)
        })
      })

      it('handles corrupted diff3 output', () => {
        useFixture('corrupted-3way-diff.txt')

        runs(() => {
          expect(conflicts.length).toBe(1)
          expect(rowRangeFrom(conflicts[0].ours.textMarker)).toEqual([13, 14])
          expect(rowRangeFrom(conflicts[0].base.textMarker)).toEqual([15, 16])
          expect(rowRangeFrom(conflicts[0].theirs.textMarker)).toEqual([17, 18])
        })
      })
    })
  })

  afterEach(() => subs.dispose())
})
