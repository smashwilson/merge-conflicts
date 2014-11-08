MergeConflictsView = require './merge-conflicts-view'
SideView = require './side-view'
NavigationView = require './navigation-view'
Conflict = require './conflict'
{GitBridge} = require './git-bridge'
handleErr = require './error-view'

module.exports =

  activate: (state) ->
    atom.workspaceView.command "merge-conflicts:detect", ->
      GitBridge.locateGitAnd (err) ->
        return handleErr(err) if err?
        MergeConflictsView.detect()

  deactivate: ->

  configDefaults:
    gitPath: '/usr/local/bin/git'

  serialize: ->
