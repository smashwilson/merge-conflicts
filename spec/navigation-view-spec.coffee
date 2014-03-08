NavigationView = require '../lib/navigation-view'

Conflict = require '../lib/conflict'
util = require './util'

describe 'NavigationView', ->
  [view] = []

  beforeEach ->
    editorView = util.openPath("single-2way-diff.txt")
    conflict = Conflict.all(editorView)[0]
    view = new NavigationView(conflict)
    view.installIn editorView

  it 'accesses the line', ->
    expect(view.line().text()).toBe('=======')

  it 'overlays the separator line', ->
    expect(view.offset().top).toBe(view.line().top)
