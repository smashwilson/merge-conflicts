MergeConflictsView = require './merge-conflicts-view'
SideView = require './side-view'
NavigationView = require './navigation-view'
Conflict = require './conflict'

module.exports =

  activate: (state) ->
    atom.workspaceView.command "merge-conflicts:detect", ->
      MergeConflictsView.detect()

    atom.workspaceView.eachEditorView (view) ->
      if view.attached and view.getPane()?
        for c in Conflict.all(view.getEditor())
          oursView = new SideView(c.ours, view)
          theirsView = new SideView(c.theirs, view)
          navView = new NavigationView(c.navigator, view)

  deactivate: ->

  serialize: ->
