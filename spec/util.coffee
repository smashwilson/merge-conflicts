{Emitter} = require 'atom'

module.exports =
  openPath: (path, callback) ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise -> atom.workspace.open(path)

    runs ->
      callback(atom.views.getView(atom.workspace.getActivePaneItem()))

  rowRangeFrom: (marker) ->
    [marker.getTailBufferPosition().row, marker.getHeadBufferPosition().row]

  pkgEmitter: ->
    emitter = new Emitter

    return {
      onDidResolveConflict: (callback) -> emitter.on 'did-resolve-conflict', callback
      didResolveConflict: (event) -> emitter.emit 'did-resolve-conflict', event
      onDidResolveFile: (callback) -> emitter.on 'did-resolve-file', callback
      didResolveFile: (event) -> emitter.emit 'did-resolve-file', event
      onDidQuitConflictResolution: (callback) -> emitter.on 'did-quit-conflict-resolution', callback
      didQuitConflictResolution: -> emitter.emit 'did-quit-conflict-resolution'
      onDidCompleteConflictResolution: (callback) -> emitter.on 'did-complete-conflict-resolution', callback
      didCompleteConflictResolution: -> emitter.emit 'did-complete-conflict-resolution'
      dispose: -> emitter.dispose()
    }
