{CompositeDisposable, Emitter} = require 'atom'

{MergeConflictsView} = require './view/merge-conflicts-view'
{handleErr} = require './view/error-view'

module.exports =

  activate: (state) ->
    @subs = new CompositeDisposable
    @emitter = new Emitter

    pkgEmitter =
      onDidResolveConflict: (callback) => @onDidResolveConflict(callback)
      didResolveConflict: (event) => @emitter.emit 'did-resolve-conflict', event
      onDidStageFile: (callback) => @onDidStageFile(callback)
      didStageFile: (event) => @emitter.emit 'did-stage-file', event
      onDidQuitConflictResolution: (callback) => @onDidQuitConflictResolution(callback)
      didQuitConflictResolution: => @emitter.emit 'did-quit-conflict-resolution'
      onDidCompleteConflictResolution: (callback) => @onDidCompleteConflictResolution(callback)
      didCompleteConflictResolution: => @emitter.emit 'did-complete-conflict-resolution'

    @subs.add atom.commands.add 'atom-workspace', 'merge-conflicts:detect', ->
      MergeConflictsView.detect(pkgEmitter)

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

  # Invoke a callback if conflict resolution is prematurely exited, while conflicts remain
  # unresolved.
  #
  onDidQuitConflictResolution: (callback) ->
    @emitter.on 'did-quit-conflict-resolution', callback

  # Invoke a callback if conflict resolution is completed successfully, with all conflicts resolved
  # and all files staged.
  #
  onDidCompleteConflictResolution: (callback) ->
    @emitter.on 'did-complete-conflict-resolution', callback
