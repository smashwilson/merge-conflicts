SideView = require '../lib/side-view'

Conflict = require '../lib/conflict'
util = require './util'

describe 'SideView', ->
  [view, editorView, ours, theirs] = []

  beforeEach ->
    editorView = util.openPath("single-2way-diff.txt")
    conflict = Conflict.all(editorView)[0]
    [ours, theirs] = [conflict.ours, conflict.theirs]
    view = new SideView(ours)

  it 'positions itself over the banner line', ->
    view.installIn editorView
    expect(view.offset().top).toEqual(ours.refBannerOffset().top)
    expect(view.height()).toEqual(ours.refBannerLine().height())

  it 'triggers conflict resolution', ->
    spyOn(ours, "resolve")
    view.useMe()
    expect(ours.resolve).toHaveBeenCalled()

  describe 'when chosen as the resolution', ->

    beforeEach ->
      view.installIn editorView
      ours.resolve()

    it 'adds the "resolved" class', ->
      classes = line.className.split /\s+/ for line in ours.lines()
      expect(classes).toContain("resolved")
      expect(classes).toContain("conflict-line")
      expect(classes).not.toContain("ours")
      expect(classes).not.toContain("theirs")

    it 'deletes the marker line'

  describe 'when not chosen as the resolution', ->

    beforeEach ->
      theirs.resolve()

    it 'deletes its hunks lines'
