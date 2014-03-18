ConflictMarker = require '../lib/conflict-marker'
util = require './util'

describe 'ConflictMarker', ->
  [editorView, editor, m] = []

  cursors = -> c.getBufferPosition().toArray() for c in editor.getCursors()

  detectDirty = ->
    for sv in m.coveringViews
      sv.detectDirty() if 'detectDirty' of sv

  beforeEach ->
    editorView = util.openPath("triple-2way-diff.txt")
    editorView.getFirstVisibleScreenRow = -> 0
    editorView.getLastVisibleScreenRow = -> 999

    editor = editorView.getEditor()

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
    detectDirty()

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
    expect(event.source).toBe(m)

  it 'tracks the active conflict side', ->
    expect(m.active()).toEqual([])
    editorView.getEditor().setCursorBufferPosition [14, 5]
    expect(m.active()).toEqual([m.conflicts[1].ours])

  describe 'with an active conflict', ->
    [active] = []

    beforeEach ->
      editor.setCursorBufferPosition [14, 5]
      active = m.conflicts[1]

    it 'accepts the current side with merge-conflicts:accept-current', ->
      editorView.trigger 'merge-conflicts:accept-current'
      expect(active.resolution).toBe(active.ours)

    it "does nothing if you have cursors in both sides", ->
      editor.addCursorAtBufferPosition [16, 2]
      editorView.trigger 'merge-conflicts:accept-current'
      expect(active.resolution).toBeNull()

    it 'accepts "ours" on merge-conflicts:accept-ours', ->
      editorView.trigger 'merge-conflicts:accept-ours'
      expect(active.resolution).toBe(active.ours)

    it 'accepts "theirs" on merge-conflicts:accept-theirs', ->
      editorView.trigger 'merge-conflicts:accept-theirs'
      expect(active.resolution).toBe(active.theirs)

    it 'jumps to the next unresolved on merge-conflicts:next-unresolved', ->
      editorView.trigger 'merge-conflicts:next-unresolved'
      expect(cursors()).toEqual([[22, 0]])

    it 'jumps to the previous unresolved on merge-conflicts:previous-unresolved', ->
      editorView.trigger 'merge-conflicts:previous-unresolved'
      expect(cursors()).toEqual([[5, 0]])

    it 'reverts a dirty hunk on merge-conflicts:revert-current', ->
      editor.insertText 'this is a change'
      detectDirty()
      expect(active.ours.isDirty).toBe(true)

      editorView.trigger 'merge-conflicts:revert-current'
      detectDirty()
      expect(active.ours.isDirty).toBe(false)

    it 'accepts ours-then-theirs on merge-conflicts:ours-then-theirs', ->
      editorView.trigger 'merge-conflicts:ours-then-theirs'
      expect(active.resolution).toBe(active.ours)
      t = editor.getTextInBufferRange active.resolution.marker.getBufferRange()
      expect(t).toBe("My middle changes\nYour middle changes\n")

    it 'accepts theirs-then-ours on merge-conflicts:theirs-then-ours', ->
      editorView.trigger 'merge-conflicts:theirs-then-ours'
      expect(active.resolution).toBe(active.theirs)
      t = editor.getTextInBufferRange active.resolution.marker.getBufferRange()
      expect(t).toBe("Your middle changes\nMy middle changes\n")

  describe 'without an active conflict', ->

    beforeEach ->
      editor.setCursorBufferPosition [11, 6]

    it 'no-ops the resolution commands', ->
      for e in ['accept-current', 'accept-ours', 'accept-theirs', 'revert-current']
        editorView.trigger "merge-conflicts:#{e}"
        expect(m.active()).toEqual([])
        for c in m.conflicts
          expect(c.isResolved()).toBe(false)

    it 'jumps to the next unresolved on merge-conflicts:next-unresolved', ->
      expect(m.active()).toEqual([])
      editorView.trigger 'merge-conflicts:next-unresolved'
      expect(cursors()).toEqual([[14, 0]])

    it 'jumps to the previous unresolved on merge-conflicts:next-unresolved', ->
      editorView.trigger 'merge-conflicts:previous-unresolved'
      expect(cursors()).toEqual([[5, 0]])

  describe 'when the resolution is complete', ->

    beforeEach -> c.ours.resolve() for c in m.conflicts

    it 'removes all of the CoveringViews', ->
      expect(editorView.find('.overlayer .side').length).toBe(0)
      expect(editorView.find('.overlayer .navigation').length).toBe(0)

    it 'removes all line classes', ->
      for klass in ['ours', 'theirs', 'parent', 'dirty']
        expect(editorView.find(".lines .#{klass}").length).toBe(0)

    it 'removes the .conflicted class', ->
      expect(editorView.hasClass 'conflicted').toBe(false)

    it 'appends a ResolverView to the editor', ->
      expect(editorView.find('.resolver').length).toBe(1)
