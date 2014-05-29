path = require 'path'
_ = require 'underscore-plus'

MergeConflictsView = require '../lib/merge-conflicts-view'
MergeState = require '../lib/merge-state'
Conflict = require '../lib/conflict'
{GitBridge} = require '../lib/git-bridge'
util = require './util'

describe 'MergeConflictsView', ->
  [view, state] = []

  fullPath = (fname) ->
    path.join atom.project.getPath(), 'path', fname

  repoPath = (fname) ->
    atom.project.getRepo().relativize fullPath(fname)

  beforeEach ->
    conflicts = _.map ['file1.txt', 'file2.txt'], (fname) ->
      { path: path.join('spec', 'fixtures', 'path', fname), message: 'both modified' }
    editorView = util.openPath 'triple-2way-diff.txt'
    state = new MergeState conflicts, false
    conflicts = Conflict.all state, editorView.getEditor()

    view = new MergeConflictsView state

  describe 'conflict resolution progress', ->
    progressFor = (filename) ->
      view.pathList.find("li:contains('#{filename}') progress")[0]

    it 'starts at zero', ->
      expect(progressFor('file1.txt').value).toBe(0)
      expect(progressFor('file2.txt').value).toBe(0)

    it 'advances when requested', ->
      atom.emit 'merge-conflicts:resolved', {
        file: fullPath('file1.txt'),
        total: 3,
        resolved: 2
      }
      progress1 = progressFor 'file1.txt'
      expect(progress1.value).toBe(2)
      expect(progress1.max).toBe(3)

  describe 'tracking the progress of staging', ->

    isMarkedWith = (filename, icon) ->
      rs = view.pathList.find("li:contains('#{filename}') span.icon-#{icon}")
      rs.length isnt 0

    it 'starts without files marked as staged', ->
      expect(isMarkedWith 'file1.txt', 'dash').toBe(true)
      expect(isMarkedWith 'file2.txt', 'dash').toBe(true)

    it 'marks files as staged on events', ->
      GitBridge.process = ({stdout, exit}) ->
        stdout("UU #{repoPath 'file2.txt'}")
        exit(0)
        { process: { on: (err) -> } }

      atom.emit 'merge-conflicts:staged', file: fullPath('file1.txt')
      expect(isMarkedWith 'file1.txt', 'check').toBe(true)
      expect(isMarkedWith 'file2.txt', 'dash').toBe(true)

  it 'minimizes and restores the view on request', ->
    expect(view.hasClass 'minimized').toBe(false)
    view.minimize()
    expect(view.hasClass 'minimized').toBe(true)
    view.restore()
    expect(view.hasClass 'minimized').toBe(false)
