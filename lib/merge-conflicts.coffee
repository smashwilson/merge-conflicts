MergeConflictsView = require './merge-conflicts-view'
SideView = require './side-view'
NavigationView = require './navigation-view'
Conflict = require './conflict'

module.exports =

  activate: (state) ->
    atom.workspaceView.command "merge-conflicts:detect", ->
      MergeConflictsView.detect()

  deactivate: ->

  configDefaults:
    gitPath: '/usr/local/bin/git'

  serialize: ->
