NavigationView = require '../lib/navigation-view'

Conflict = require '../lib/conflict'
util = require './util'

describe 'NavigationView', ->
  [view, editorView, editor, conflicts, conflict] = []

  beforeEach ->
    editorView = util.openPath("triple-2way-diff.txt")
    editor = editorView.getEditor()
    conflicts = Conflict.all({}, editor)
    conflict = conflicts[1]

    view = new NavigationView(conflict.navigator, editorView)

  it 'deletes the separator line on resolution', ->
    c.ours.resolve() for c in conflicts
    text = editor.getText()
    expect(text).not.toContain("My middle changes\n=======\nYour middle changes")

  it 'scrolls to the next diff', ->
    spyOn(editor, "setCursorBufferPosition")
    view.down()
    p = conflicts[2].ours.marker.getTailBufferPosition()
    expect(editor.setCursorBufferPosition).toHaveBeenCalledWith(p)

  it 'scrolls to the previous diff', ->
    spyOn(editor, "setCursorBufferPosition")
    view.up()
    p = conflicts[0].ours.marker.getTailBufferPosition()
    expect(editor.setCursorBufferPosition).toHaveBeenCalledWith(p)
