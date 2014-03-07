SideView = require '../lib/side-view'

Conflict = require '../lib/conflict'
util = require './util'

describe 'SideView', ->
  [view, ours, theirs] = []

  beforeEach ->
    editor = util.openPath("single-2way-diff.txt").getEditor()
    conflict = Conflict.all(editor)[0]
    [ours, theirs] = [conflict.ours, conflict.theirs]
    view = new SideView(ours)

  it 'triggers conflict resolution', ->
    spyOn(ours, "resolve")
    view.useMe()
    expect(ours.resolve).toHaveBeenCalled()

  describe 'when chosen as the resolution', ->

    beforeEach ->
      ours.resolve()

    it 'adds the "resolved" class'
    it 'deletes the marker line'

  describe 'when not chosen as the resolution', ->

    beforeEach ->
      theirs.resolve()

    it 'deletes its hunks lines'
    it ''
