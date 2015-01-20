{CompositeDisposable, Emitter} = require 'atom'
{MergeConflictsView} = require './merge-conflicts-view'
{GitBridge} = require './git-bridge'
handleErr = require './error-view'

module.exports =

  activate: (state) ->
    @subs = new CompositeDisposable
    @emitter = new Emitter

    pkgEmitter =
      didResolveConflict: (event) => @emitter.emit 'did-resolve-conflict', event
      didStageFile: (event) => @emitter.emit 'did-stage-file', event

    @subs.add atom.commands.add 'atom-workspace', 'merge-conflicts:detect', ->
      GitBridge.locateGitAnd (err) ->
        return handleErr(err) if err?
        MergeConflictsView.detect()

  deactivate: ->
    @subs.dispose()
    @emitter.dispose()

  config:
    gitPath:
      type: 'string'
      default: ''
      description: 'Absolute path to your git executable.'

  # Invoke a callback each time that an individual conflict is resolved.
  #
  onDidResolveConflict: (callback) ->
    @emitter.on 'did-resolve-conflict', callback

  # Invoke a callback each time that a completed file is staged.
  #
  onDidStageFile: (callback) ->
    @emitter.on 'did-stage-file', callback
