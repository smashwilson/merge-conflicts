{$} = require 'space-pen'
{SideView} = require '../../lib/view/side-view'

{Conflict} = require '../../lib/conflict'
util = require '../util'

describe 'SideView', ->
  [view, editorView, ours, theirs] = []

  text = -> editorView.getModel().getText()

  beforeEach ->
    util.openPath "single-2way-diff.txt", (v) ->
      editor = v.getModel()
      editorView = v
      conflict = Conflict.all({ isRebase: false }, editor)[0]
      [ours, theirs] = [conflict.ours, conflict.theirs]
      view = new SideView(ours, editor)

  it 'applies its position as a CSS class', ->
    expect(view.hasClass 'top').toBe(true)
    expect(view.hasClass 'bottom').toBe(false)

  it 'knows if its text is unaltered', ->
    expect(ours.isDirty).toBe(false)
    expect(theirs.isDirty).toBe(false)

  describe 'when its text has been edited', ->
    [editor] = []

    beforeEach ->
      editor = editorView.getModel()
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

  describe 'conflict resolution', ->
    it 'should call `resolve` for simple resolutions ("Use Me")' ->
      spyOn(ours, "resolve")
      view.useMe()
      expect(ours.resolve).toHaveBeenCalled()
      
    describe 'complex resolutions ("Keep Both")' ->
      it 'should have an instance of `ConflictedEditor`' ->
        expect(ours.editor).toBeDefined()
        ## TODO: expect(ours.editor).toBe("ConflictedEditor")...?

      it 'should call `ConflictedEditor#acceptOursThenTheirs` for "Use Me First"' ->
        ## TODO: Setup spy
        ## TODO: expect(spy).toHaveBeenCalled()

      it 'should call `ConflictedEditor#acceptTheirsThenOurs` for "Use Me Last"' ->
        ## TODO: Setup...
        ## TODO: expect(spy).toHaveBeenCalled()

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
