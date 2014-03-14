ConflictMarker = require '../lib/conflict-marker'
util = require './util'

describe 'ConflictMarker', ->
  [editorView, m] = []

  beforeEach ->
    editorView = util.openPath("triple-2way-diff.txt")
    editorView.getFirstVisibleScreenRow = -> 0
    editorView.getLastVisibleScreenRow = -> 999

    m = new ConflictMarker(editorView)

  it 'attaches two SideViews and a NavigationView for each conflict', ->
    expect(editorView.find('.side').length).toBe(6)
    expect(editorView.find('.navigation').length).toBe(3)

  it 'adds the conflicted class', ->
    expect(editorView.hasClass 'conflicted').toBe(true)

  it 'removes any old classes', ->
    line = editorView.renderedLines.eq(2)
    line.addClass "ours"
    m.remark()
    expect(line.hasClass 'ours').toBe(false)

  it 'locates the correct lines', ->
    lines = m.linesForMarker m.conflicts[1].ours.marker
    expect(lines.text()).toBe("My middle changes")

  it 'applies the "ours" class to our sides of conflicts', ->
    lines = m.linesForMarker m.conflicts[0].ours.marker
    expect(lines.hasClass 'conflict-line').toBe(true)
    expect(lines.hasClass 'ours').toBe(true)

  it 'applies the "theirs" class to their sides of conflicts', ->
    lines = m.linesForMarker m.conflicts[0].theirs.marker
    expect(lines.hasClass 'conflict-line').toBe(true)
    expect(lines.hasClass 'theirs').toBe(true)

  it 'applies the "dirty" class to modified sides', ->
    editor = editorView.getEditor()
    editor.setCursorBufferPosition [14, 0]
    editor.insertText "Make conflict 1 dirty"
    for sv in m.coveringViews
      sv.detectDirty() if 'detectDirty' of sv

    m.remark()
    lines = m.linesForMarker m.conflicts[1].ours.marker
    expect(lines.hasClass 'dirty').toBe(true)
    expect(lines.hasClass 'ours').toBe(false)

  it 'applies the "resolved" class to resolved conflicts', ->
    m.conflicts[1].ours.resolve()
    m.remark()
    lines = m.linesForMarker m.conflicts[1].ours.marker
    expect(lines.hasClass 'conflict-line').toBe(true)
    expect(lines.hasClass 'resolved').toBe(true)

  it 'broadcasts the "merge-conflicts:resolved" event', ->
    event = null
    atom.on 'merge-conflicts:resolved', (e) -> event = e
    m.conflicts[2].theirs.resolve()

    expect(event.file).toBe(editorView.getEditor().getPath())
    expect(event.total).toBe(3)
    expect(event.resolved).toBe(1)

  it 'tracks the active conflict side', ->
    expect(m.active()).toEqual([])
    editorView.getEditor().setCursorBufferPosition [14, 5]
    expect(m.active()).toEqual([m.conflicts[1].ours])

  describe 'with an active conflict', ->
    [editor, active] = []

    beforeEach ->
      editor = editorView.getEditor()
      editor.setCursorBufferPosition [14, 5]
      active = m.conflicts[1]

    it 'accepts the current side with merge-conflicts:resolve-current', ->
      editorView.trigger 'merge-conflicts:resolve-current'
      expect(active.resolution).toBe(active.ours)

    it "does nothing if you have cursors in both sides", ->
      editor.addCursorAtBufferPosition [16, 2]
      editorView.trigger 'merge-conflicts:resolve-current'
      expect(active.resolution).toBeNull()

    it 'accepts "ours" on merge-conflicts:accept-ours', ->
      editorView.trigger 'merge-conflicts:accept-ours'
      expect(active.resolution).toBe(active.ours)

    it 'accepts "theirs" on merge-conflicts:accept-theirs', ->
      editorView.trigger 'merge-conflicts:accept-theirs'
      expect(active.resolution).toBe(active.theirs)

    it 'jumps to the next unresolved on merge-conflicts:next-unresolved', ->
      editorView.trigger 'merge-conflicts:next-unresolved'
      cs = (c.getBufferPosition().toArray() for c in editor.getCursors())
      expect(cs).toEqual([[22, 0]])

    it 'jumps to the previous unresolved on merge-conflicts:previous-unresolved', ->
      editorView.trigger 'merge-conflicts:previous-unresolved'
      cs = (c.getBufferPosition().toArray() for c in editor.getCursors())
      expect(cs).toEqual([[5, 0]])

  describe 'without an active conflict', ->
    it 'no-ops the resolution commands'
    it 'jumps to the next unresolved on merge-conflicts:next-unresolved'
    it 'jumps to the previous unresolved on merge-conflicts:next-unresolved'
