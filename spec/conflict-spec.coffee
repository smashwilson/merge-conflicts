Conflict = require '../lib/conflict'
util = require './util'

describe "Conflict", ->

  rowRangeFrom = (marker) ->
    [marker.getTailBufferPosition().row, marker.getHeadBufferPosition().row]

  it "parses itself from a two-way diff marking", ->
    editor = util.openPath('single-2way-diff.txt').getEditor()
    c = Conflict.all(editor)[0]

    expect(rowRangeFrom c.ours.marker).toEqual([1, 2])
    expect(c.ours.ref).toBe('HEAD')
    expect(rowRangeFrom c.theirs.marker).toEqual([3, 4])
    expect(c.theirs.ref).toBe('master')

  it "finds multiple conflict markings", ->
    editor = util.openPath('multi-2way-diff.txt').getEditor()
    cs = Conflict.all(editor)

    expect(cs.length).toBe(2)
    expect(rowRangeFrom cs[0].ours.marker).toEqual([5, 7])
    expect(rowRangeFrom cs[0].theirs.marker).toEqual([8, 9])
    expect(rowRangeFrom cs[1].ours.marker).toEqual([14, 15])
    expect(rowRangeFrom cs[1].theirs.marker).toEqual([16, 17])

  describe 'sides', ->
    [conflict] = []

    beforeEach ->
      editor = util.openPath('single-2way-diff.txt').getEditor()
      [conflict] = Conflict.all editor

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

  it "parses itself from a three-way diff marking"
  it "names the incoming changes"
  it "resolves HEAD"
