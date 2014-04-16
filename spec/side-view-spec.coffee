{$} = require 'atom'
SideView = require '../lib/side-view'
Conflict = require '../lib/conflict'
util = require './util'

describe 'SideView', ->
  [view, editorView, ours, theirs] = []

  text = -> editorView.getEditor().getText()

  beforeEach ->
    editorView = util.openPath("single-2way-diff.txt")
    conflict = Conflict.all({ isRebase: false }, editorView.getEditor())[0]
    [ours, theirs] = [conflict.ours, conflict.theirs]
    view = new SideView(ours, editorView)

  it 'applies its position as a CSS class', ->
    expect(view.hasClass 'top').toBe(true)
    expect(view.hasClass 'bottom').toBe(false)

  it 'positions itself over the banner line', ->
    refBanner = editorView.find('.line:contains("<<<<<<<")').eq 0
    expect(view.offset().top).toEqual(refBanner.offset().top)
    expect(view.height()).toEqual(refBanner.height())

  it 'knows if its text is unaltered', ->
    expect(ours.isDirty).toBe(false)
    expect(theirs.isDirty).toBe(false)

  describe 'when its text has been edited', ->
    [editor] = []

    beforeEach ->
      editor = editorView.getEditor()
      editor.setCursorBufferPosition [1, 0]
      editor.insertText "I won't keep them, but "
      view.detectDirty()

    it 'detects that its text has been edited', ->
      expect(ours.isDirty).toBe(true)

    it 'adds a .dirty class to the view', ->
      expect(view.hasClass 'dirty').toBe(true)

    it 'reverts its text back to the original on request', ->
      view.revert()
      view.detectDirty()
      t = editor.getTextInBufferRange ours.marker.getBufferRange()
      expect(t).toBe("These are my changes\n")
      expect(ours.isDirty).toBe(false)

  it 'triggers conflict resolution', ->
    spyOn(ours, "resolve")
    view.useMe()
    expect(ours.resolve).toHaveBeenCalled()

  describe 'when chosen as the resolution', ->

    beforeEach ->
      ours.resolve()

    it 'deletes the marker line', ->
      expect(text()).not.toContain("<<<<<<< HEAD")

  describe 'when not chosen as the resolution', ->

    beforeEach ->
      theirs.resolve()

    it 'deletes its lines', ->
      expect(text()).not.toContain("These are my changes")

    it 'deletes the marker line', ->
      expect(text()).not.toContain("<<<<<<< HEAD")
