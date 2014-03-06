MergeConflictsView = require './merge-conflicts-view'
SideView = require './side-view'
Conflict = require './conflict'

module.exports =

  activate: (state) ->
    atom.workspaceView.command "merge-conflicts:detect", ->
      MergeConflictsView.detect()

    atom.workspaceView.eachEditorView (view) ->
      for c in Conflict.all(view)
        oursView = new SideView(c.ours)
        oursView.installIn view

        theirsView = new SideView(c.theirs)
        theirsView.installIn view

  deactivate: ->

  serialize: ->
