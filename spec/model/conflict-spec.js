'use babel'
/* global describe it expect beforeEach afterEach */

import {CompositeDisposable} from 'atom'
import {makeConflict} from '../builders'

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
    describe('single two-way diff', () => {
      it('identifies the correct rows')
      it('finds the ref banners')
      it('finds the separator')
      it('marks "ours" as the top and "theirs" as the bottom')
      it('does not have a base side')
    })

    describe('single three-way diff', () => {
      it('identifies the correct rows')
      it('finds all three ref banners')
      it('finds the separators')
      it('marks "ours" as the top and "theirs" as the bottom')
    })

    describe('complex three-way diff', () => {
      it('identifies the correct rows for complex three-way diffs')
    })

    describe('multiple two-way diffs', () => {
      it('finds all conflict markings')
    })

    describe('when rebasing', () => {
      it('swaps the lines for "ours" and "theirs"')
      it('recognizes banner lines with commit shortlog messages')
      it('marks "theirs" as the top and "ours" as the bottom')
    })

    describe('corrupted diff markers', () => {
      it('handles corrupted diff output')
      it('handles corrupted diff3 output')
    })
  })

  afterEach(() => subs.dispose())
})
