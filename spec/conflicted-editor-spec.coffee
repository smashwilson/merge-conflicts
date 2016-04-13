{$} = require 'space-pen'
_ = require 'underscore-plus'

{ConflictedEditor} = require '../lib/conflicted-editor'
{GitOps} = require '../lib/git'
util = require './util'

describe 'ConflictedEditor', ->
  [editorView, editor, state, m, pkg] = []

  cursors = -> c.getBufferPosition().toArray() for c in editor.getCursors()

  detectDirty = ->
    for sv in m.coveringViews
      sv.detectDirty() if 'detectDirty' of sv

  linesForMarker = (marker) ->
    fromBuffer = marker.getTailBufferPosition()
    fromScreen = editor.screenPositionForBufferPosition fromBuffer
    toBuffer = marker.getHeadBufferPosition()
    toScreen = editor.screenPositionForBufferPosition toBuffer

    result = $()
    for row in _.range(fromScreen.row, toScreen.row)
      result = result.add editorView.component.lineNodeForScreenRow(row)
    result

  beforeEach ->
    pkg = util.pkgEmitter()

  afterEach ->
    pkg.dispose()

    m?.cleanup()

  describe 'with a merge conflict', ->

    beforeEach ->
      util.openPath "triple-2way-diff.txt", (v) ->
        editorView = v
        editorView.getFirstVisibleScreenRow = -> 0
        editorView.getLastVisibleScreenRow = -> 999

        editor = editorView.getModel()
        state =
          isRebase: false
          relativize: (filepath) -> filepath
          context:
            isResolvedFile: (filepath) -> Promise.resolve false

        m = new ConflictedEditor(state, pkg, editor)
        m.mark()

    it 'attaches two SideViews and a NavigationView for each conflict', ->
      expect($(editorView).find('.side').length).toBe(6)
      expect($(editorView).find('.navigation').length).toBe(3)

    it 'locates the correct lines', ->
      lines = linesForMarker m.conflicts[1].ours.marker
      expect(lines.text()).toBe("My middle changes")

    it 'applies the "ours" class to our sides of conflicts', ->
      lines = linesForMarker m.conflicts[0].ours.marker
      expect(lines.hasClass 'conflict-ours').toBe(true)

    it 'applies the "theirs" class to their sides of conflicts', ->
      lines = linesForMarker m.conflicts[0].theirs.marker
      expect(lines.hasClass 'conflict-theirs').toBe(true)

    it 'applies the "dirty" class to modified sides', ->
      editor.setCursorBufferPosition [14, 0]
      editor.insertText "Make conflict 1 dirty"
      detectDirty()

      lines = linesForMarker m.conflicts[1].ours.marker
      expect(lines.hasClass 'conflict-dirty').toBe(true)
      expect(lines.hasClass 'conflict-ours').toBe(false)

    it 'broadcasts the onDidResolveConflict event', ->
      event = null
      pkg.onDidResolveConflict (e) -> event = e
      m.conflicts[2].theirs.resolve()

      expect(event.file).toBe(editor.getPath())
      expect(event.total).toBe(3)
      expect(event.resolved).toBe(1)
      expect(event.source).toBe(m)

    it 'tracks the active conflict side', ->
      editor.setCursorBufferPosition [11, 0]
      expect(m.active()).toEqual([])
      editor.setCursorBufferPosition [14, 5]
      expect(m.active()).toEqual([m.conflicts[1].ours])

    describe 'with an active merge conflict', ->
      [active] = []

      beforeEach ->
        editor.setCursorBufferPosition [14, 5]
        active = m.conflicts[1]

      it 'accepts the current side with merge-conflicts:accept-current', ->
        atom.commands.dispatch editorView, 'merge-conflicts:accept-current'
        expect(active.resolution).toBe(active.ours)

      it "does nothing if you have cursors in both sides", ->
        editor.addCursorAtBufferPosition [16, 2]
        atom.commands.dispatch editorView, 'merge-conflicts:accept-current'
        expect(active.resolution).toBeNull()

      it 'accepts "ours" on merge-conflicts:accept-ours', ->
        atom.commands.dispatch editorView, 'merge-conflicts:accept-current'
        expect(active.resolution).toBe(active.ours)

      it 'accepts "theirs" on merge-conflicts:accept-theirs', ->
        atom.commands.dispatch editorView, 'merge-conflicts:accept-theirs'
        expect(active.resolution).toBe(active.theirs)

      it 'jumps to the next unresolved on merge-conflicts:next-unresolved', ->
        atom.commands.dispatch editorView, 'merge-conflicts:next-unresolved'
        expect(cursors()).toEqual([[22, 0]])

      it 'jumps to the previous unresolved on merge-conflicts:previous-unresolved', ->
        atom.commands.dispatch editorView, 'merge-conflicts:previous-unresolved'
        expect(cursors()).toEqual([[5, 0]])

      it 'reverts a dirty hunk on merge-conflicts:revert-current', ->
        editor.insertText 'this is a change'
        detectDirty()
        expect(active.ours.isDirty).toBe(true)

        atom.commands.dispatch editorView, 'merge-conflicts:revert-current'
        detectDirty()
        expect(active.ours.isDirty).toBe(false)

      it 'accepts ours-then-theirs on merge-conflicts:ours-then-theirs', ->
        atom.commands.dispatch editorView, 'merge-conflicts:ours-then-theirs'
        expect(active.resolution).toBe(active.ours)
        t = editor.getTextInBufferRange active.resolution.marker.getBufferRange()
        expect(t).toBe("My middle changes\nYour middle changes\n")

      it 'accepts theirs-then-ours on merge-conflicts:theirs-then-ours', ->
        atom.commands.dispatch editorView, 'merge-conflicts:theirs-then-ours'
        expect(active.resolution).toBe(active.theirs)
        t = editor.getTextInBufferRange active.resolution.marker.getBufferRange()
        expect(t).toBe("Your middle changes\nMy middle changes\n")

    describe 'without an active conflict', ->

      beforeEach ->
        editor.setCursorBufferPosition [11, 6]

      it 'no-ops the resolution commands', ->
        for e in ['accept-current', 'accept-ours', 'accept-theirs', 'revert-current']
          atom.commands.dispatch editorView, "merge-conflicts:#{e}"
          expect(m.active()).toEqual([])
          for c in m.conflicts
            expect(c.isResolved()).toBe(false)

      it 'jumps to the next unresolved on merge-conflicts:next-unresolved', ->
        expect(m.active()).toEqual([])
        atom.commands.dispatch editorView, 'merge-conflicts:next-unresolved'
        expect(cursors()).toEqual([[14, 0]])

      it 'jumps to the previous unresolved on merge-conflicts:next-unresolved', ->
        atom.commands.dispatch editorView, 'merge-conflicts:previous-unresolved'
        expect(cursors()).toEqual([[5, 0]])

    describe 'when the resolution is complete', ->

      beforeEach -> c.ours.resolve() for c in m.conflicts

      it 'removes all of the CoveringViews', ->
        expect($(editorView).find('.overlayer .side').length).toBe(0)
        expect($(editorView).find('.overlayer .navigation').length).toBe(0)

      it 'appends a ResolverView to the workspace', ->
        workspaceView = atom.views.getView atom.workspace
        expect($(workspaceView).find('.resolver').length).toBe(1)

    describe 'when all resolutions are complete', ->

      beforeEach ->
        c.theirs.resolve() for c in m.conflicts
        pkg.didCompleteConflictResolution()

      it 'destroys all Conflict markers', ->
        for c in m.conflicts
          for marker in c.markers()
            expect(marker.isDestroyed()).toBe(true)

      it 'removes the .conflicted class', ->
        expect($(editorView).hasClass 'conflicted').toBe(false)

  describe 'with a rebase conflict', ->
    [active] = []

    beforeEach ->
      util.openPath "rebase-2way-diff.txt", (v) ->
        editorView = v
        editorView.getFirstVisibleScreenRow = -> 0
        editorView.getLastVisibleScreenRow = -> 999

        editor = editorView.getModel()
        state =
          isRebase: true
          relativize: (filepath) -> filepath
          context:
            isResolvedFile: -> Promise.resolve(false)

        m = new ConflictedEditor(state, pkg, editor)
        m.mark()

        editor.setCursorBufferPosition [3, 14]
        active = m.conflicts[0]

    it 'accepts theirs-then-ours on merge-conflicts:theirs-then-ours', ->
      atom.commands.dispatch editorView, 'merge-conflicts:theirs-then-ours'
      expect(active.resolution).toBe(active.theirs)
      t = editor.getTextInBufferRange active.resolution.marker.getBufferRange()
      expect(t).toBe("These are your changes\nThese are my changes\n")

    it 'accepts ours-then-theirs on merge-conflicts:ours-then-theirs', ->
      atom.commands.dispatch editorView, 'merge-conflicts:ours-then-theirs'
      expect(active.resolution).toBe(active.ours)
      t = editor.getTextInBufferRange active.resolution.marker.getBufferRange()
      expect(t).toBe("These are my changes\nThese are your changes\n")
