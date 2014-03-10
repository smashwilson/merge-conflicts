Conflict = require '../lib/conflict'
util = require './util'

describe "Conflict", ->

  describe 'a single two-way diff', ->
    [conflict] = []

    beforeEach ->
      editorView = util.openPath('single-2way-diff.txt')
      conflict = Conflict.all(editorView.getEditor())[0]

    it 'identifies the correct rows', ->
      expect(util.rowRangeFrom conflict.ours.marker).toEqual([1, 2])
      expect(conflict.ours.ref).toBe('HEAD')
      expect(util.rowRangeFrom conflict.theirs.marker).toEqual([3, 4])
      expect(conflict.theirs.ref).toBe('master')

    it 'finds the ref banners', ->
      expect(util.rowRangeFrom conflict.ours.refBannerMarker).toEqual([0, 1])
      expect(util.rowRangeFrom conflict.theirs.refBannerMarker).toEqual([4, 5])

    it 'finds the separator', ->
      expect(util.rowRangeFrom conflict.separatorMarker).toEqual([2, 3])

    it 'iterates the DOM lines', ->
      lines = conflict.theirs.lines()

      expect(lines.length).toBe(1)
      expect(lines.eq(0).text()).toBe("These are your changes")

  it "finds multiple conflict markings", ->
    editorView = util.openPath('multi-2way-diff.txt')
    cs = Conflict.all(editorView)

    expect(cs.length).toBe(2)
    expect(util.rowRangeFrom cs[0].ours.marker).toEqual([5, 7])
    expect(util.rowRangeFrom cs[0].theirs.marker).toEqual([8, 9])
    expect(util.rowRangeFrom cs[1].ours.marker).toEqual([14, 15])
    expect(util.rowRangeFrom cs[1].theirs.marker).toEqual([16, 17])

  describe 'sides', ->
    [conflict] = []

    beforeEach ->
      editorView = util.openPath('single-2way-diff.txt')
      [conflict] = Conflict.all editorView

    it 'retains a reference to conflict', ->
      expect(conflict.ours.conflict).toBe(conflict)
      expect(conflict.theirs.conflict).toBe(conflict)

    it 'resolves as "ours"', ->
      conflict.ours.resolve()

      expect(conflict.resolution).toBe(conflict.ours)
      expect(conflict.ours.wasChosen()).toBe(true)
      expect(conflict.theirs.wasChosen()).toBe(false)

    it 'resolves as "theirs"', ->
      conflict.theirs.resolve()

      expect(conflict.resolution).toBe(conflict.theirs)
      expect(conflict.ours.wasChosen()).toBe(false)
      expect(conflict.theirs.wasChosen()).toBe(true)

    it 'broadcasts an event', ->
      resolved = false
      conflict.on "conflict:resolved", -> resolved = true
      conflict.ours.resolve()
      expect(resolved).toBe(true)

  it "parses itself from a three-way diff marking"
  it "names the incoming changes"
  it "resolves HEAD"
