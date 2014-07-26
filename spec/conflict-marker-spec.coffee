ConflictMarker = require '../lib/conflict-marker'
{GitBridge} = require '../lib/git-bridge'
util = require './util'

describe 'ConflictMarker', ->
  [editorView, editor, state, m] = []

  cursors = -> c.getBufferPosition().toArray() for c in editor.getCursors()

  detectDirty = ->
    for sv in m.coveringViews
      sv.detectDirty() if 'detectDirty' of sv

  describe 'with a merge conflict', ->

    beforeEach ->
      GitBridge._gitCommand = -> 'git'

      editorView = util.openPath("triple-2way-diff.txt")
      editorView.getFirstVisibleScreenRow = -> 0
      editorView.getLastVisibleScreenRow = -> 999

      editor = editorView.getEditor()
      state =
        isRebase: false

      m = new ConflictMarker(state, editorView)

    it 'attaches two SideViews and a NavigationView for each conflict', ->
      expect(editorView.find('.side').length).toBe(6)
      expect(editorView.find('.navigation').length).toBe(3)

    it 'adds the conflicted class', ->
      expect(editorView.hasClass 'conflicted').toBe(true)

    it 'locates the correct lines', ->
      lines = m.linesForMarker m.conflicts[1].ours.marker
      expect(lines.text()).toBe("My middle changes")

    it 'applies the "ours" class to our sides of conflicts', ->
      lines = m.linesForMarker m.conflicts[0].ours.marker
      expect(lines.hasClass 'conflict-ours').toBe(true)

    it 'applies the "theirs" class to their sides of conflicts', ->
      lines = m.linesForMarker m.conflicts[0].theirs.marker
      expect(lines.hasClass 'conflict-theirs').toBe(true)

    it 'applies the "dirty" class to modified sides', ->
      editor = editorView.getEditor()
      editor.setCursorBufferPosition [14, 0]
      editor.insertText "Make conflict 1 dirty"
      detectDirty()

      lines = m.linesForMarker m.conflicts[1].ours.marker
      expect(lines.hasClass 'conflict-dirty').toBe(true)
      expect(lines.hasClass 'conflict-ours').toBe(false)

    it 'broadcasts the "merge-conflicts:resolved" event', ->
      event = null
      atom.on 'merge-conflicts:resolved', (e) -> event = e
      m.conflicts[2].theirs.resolve()

      expect(event.file).toBe(editorView.getEditor().getPath())
      expect(event.total).toBe(3)
      expect(event.resolved).toBe(1)
      expect(event.source).toBe(m)

    it 'tracks the active conflict side', ->
      editorView.getEditor().setCursorBufferPosition [11, 0]
      expect(m.active()).toEqual([])
      editorView.getEditor().setCursorBufferPosition [14, 5]
      expect(m.active()).toEqual([m.conflicts[1].ours])

    describe 'with an active merge conflict', ->
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

      it 'removes the .conflicted class', ->
        expect(editorView.hasClass 'conflicted').toBe(false)

      it 'appends a ResolverView to the editor', ->
        expect(editorView.find('.resolver').length).toBe(1)

  describe 'with a rebase conflict', ->
    [active] = []

    beforeEach ->
      GitBridge._gitCommand = -> 'git'

      editorView = util.openPath("rebase-2way-diff.txt")
      editorView.getFirstVisibleScreenRow = -> 0
      editorView.getLastVisibleScreenRow = -> 999

      editor = editorView.getEditor()
      state =
        isRebase: true

      m = new ConflictMarker(state, editorView)

      editor.setCursorBufferPosition [3, 14]
      active = m.conflicts[0]

    it 'accepts theirs-then-ours on merge-conflicts:theirs-then-ours', ->
      editorView.trigger 'merge-conflicts:theirs-then-ours'
      expect(active.resolution).toBe(active.theirs)
      t = editor.getTextInBufferRange active.resolution.marker.getBufferRange()
      expect(t).toBe("These are your changes\nThese are my changes\n")

    it 'accepts ours-then-theirs on merge-conflicts:ours-then-theirs', ->
      editorView.trigger 'merge-conflicts:ours-then-theirs'
      expect(active.resolution).toBe(active.ours)
      t = editor.getTextInBufferRange active.resolution.marker.getBufferRange()
      expect(t).toBe("These are my changes\nThese are your changes\n")
