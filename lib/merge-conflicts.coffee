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

  config:
    gitPath:
      type: 'string'
      default: ''
      description: 'Absolute path to your git executable.'

  serialize: ->
