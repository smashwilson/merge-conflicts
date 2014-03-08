NavigationView = require '../lib/navigation-view'

Conflict = require '../lib/conflict'
util = require './util'

describe 'NavigationView', ->
  [view, editorView, conflict] = []

  beforeEach ->
    editorView = util.openPath("single-2way-diff.txt")
    conflict = Conflict.all(editorView)[0]
    view = new NavigationView(conflict)
    view.installIn editorView

  it 'accesses the line', ->
    expect(view.line().text()).toBe('=======')

  it 'deletes the separator line on resolution', ->
    conflict.ours.resolve()
    text = editorView.getEditor().getText()
    expect(text).not.toContain('=======')
