path = require 'path'
_ = require 'underscore-plus'

MergeConflictsView = require '../lib/merge-conflicts-view'
Conflict = require '../lib/conflict'
util = require './util'

describe 'MergeConflictsView', ->
  [view, conflicts] = []

  beforeEach ->
    conflictPaths = _.map ['file1.txt', 'file2.txt'], (p) ->
      path.join(atom.project.getPath(), 'path', p)
    editorView = util.openPath 'triple-2way-diff.txt'
    conflicts = Conflict.all editorView.getEditor()

    view = new MergeConflictsView(conflictPaths)

  describe 'conflict resolution progress', ->
    progressFor = (filename) ->
      view.pathList.find("li:contains('#{filename}') progress")[0]

    it 'starts at zero', ->
      expect(progressFor('file1.txt').value).toBe(0)
      expect(progressFor('file2.txt').value).toBe(0)

    it 'advances when requested', ->
      p = path.join(atom.project.getPath(), 'path', 'file1.txt')
      atom.emit 'merge-conflicts:resolve', file: p, total: 3
      progress1 = progressFor 'file1.txt'
      expect(progress1.value).toBe(1)
      expect(progress1.max).toBe(3)
