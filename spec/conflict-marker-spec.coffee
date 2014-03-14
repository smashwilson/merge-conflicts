ConflictMarker = require '../lib/conflict-marker'
util = require './util'

describe 'ConflictMarker', ->
  [editorView] = []

  beforeEach ->
    editorView = util.openPath("triple-2way-diff.txt")
    editorView.getFirstVisibleScreenRow = -> 0
    editorView.getLastVisibleScreenRow = -> 999

  it 'attaches two SideViews and a NavigationView for each conflict', ->
    new ConflictMarker(editorView)
    expect(editorView.find('.side').length).toBe(6)
    expect(editorView.find('.navigation').length).toBe(3)

  it 'adds the conflicted class', ->
    new ConflictMarker(editorView)
    expect(editorView.hasClass 'conflicted').toBe(true)

  it 'removes any old classes', ->
    line = editorView.renderedLines.eq(2)
    line.addClass "ours"
    new ConflictMarker(editorView)
    expect(line.hasClass 'ours').toBe(false)

  it 'locates the correct lines', ->
    m = new ConflictMarker(editorView)
    lines = m.linesForMarker m.conflicts[1].ours.marker
    expect(lines.text()).toBe("My middle changes")

  it 'applies the "ours" class to our sides of conflicts', ->
    m = new ConflictMarker(editorView)
    lines = m.linesForMarker m.conflicts[0].ours.marker
    expect(lines.hasClass 'conflict-line').toBe(true)
    expect(lines.hasClass 'ours').toBe(true)

  it 'applies the "theirs" class to their sides of conflicts', ->
    m = new ConflictMarker(editorView)
    lines = m.linesForMarker m.conflicts[0].theirs.marker
    expect(lines.hasClass 'conflict-line').toBe(true)
    expect(lines.hasClass 'theirs').toBe(true)

  it 'applies the "resolved" class to resolved conflicts', ->
    m = new ConflictMarker(editorView)
    m.conflicts[1].ours.resolve()
    m.remark()
    lines = m.linesForMarker m.conflicts[1].ours.marker
    expect(lines.hasClass 'conflict-line').toBe(true)
    expect(lines.hasClass 'resolved').toBe(true)

  it 'broadcasts the "merge-conflicts:resolved" event', ->
    m = new ConflictMarker(editorView)

    event = null
    atom.on 'merge-conflicts:resolved', (e) -> event = e
    m.conflicts[2].theirs.resolve()

    expect(event.file).toBe(editorView.getEditor().getPath())
    expect(event.total).toBe(3)
