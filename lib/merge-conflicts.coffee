{CompositeDisposable} = require 'atom'
MergeConflictsView = require './merge-conflicts-view'
{GitBridge} = require './git-bridge'
handleErr = require './error-view'

subs = new CompositeDisposable

module.exports =

  activate: (state) ->
    subs.add atom.commands.add 'atom-workspace', 'merge-conflicts:detect', ->
      GitBridge.locateGitAnd (err) ->
        return handleErr(err) if err?
        MergeConflictsView.detect()

  deactivate: ->
    subs.dispose()

  config:
    gitPath:
      type: 'string'
      default: ''
      description: 'Absolute path to your git executable.'

  serialize: ->
