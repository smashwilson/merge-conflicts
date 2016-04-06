{CompositeDisposable, Emitter} = require 'atom'

{MergeConflictsView} = require './view/merge-conflicts-view'
{GitOps} = require './git'

pkgEmitter = null;

module.exports =

  activate: (state) ->
    @subs = new CompositeDisposable
    @emitter = new Emitter

    MergeConflictsView.registerContextApi(GitOps);

    pkgEmitter =
      onDidResolveConflict: (callback) => @onDidResolveConflict(callback)
      didResolveConflict: (event) => @emitter.emit 'did-resolve-conflict', event
      onDidResolveFile: (callback) => @onDidResolveFile(callback)
      didResolveFile: (event) => @emitter.emit 'did-resolve-file', event
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

  # Invoke a callback each time that a completed file is resolved.
  #
  onDidResolveFile: (callback) ->
    @emitter.on 'did-resolve-file', callback

  # Invoke a callback if conflict resolution is prematurely exited, while conflicts remain
  # unresolved.
  #
  onDidQuitConflictResolution: (callback) ->
    @emitter.on 'did-quit-conflict-resolution', callback

  # Invoke a callback if conflict resolution is completed successfully, with all conflicts resolved
  # and all files resolved.
  #
  onDidCompleteConflictResolution: (callback) ->
    @emitter.on 'did-complete-conflict-resolution', callback

  provideApi: ->
    _ = require 'underscore-plus'
    _.extend({}, pkgEmitter, {
      registerContextApi: (contextApi) =>
        MergeConflictsView.registerContextApi(contextApi);
    });
