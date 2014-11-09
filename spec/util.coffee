{WorkspaceView} = require 'atom'

module.exports =
  openPath: (path, callback) ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.attachToDom()

    waitsForPromise -> atom.workspaceView.open(path)

    runs ->
      callback(atom.workspaceView.getActiveView())

  rowRangeFrom: (marker) ->
    [marker.getTailBufferPosition().row, marker.getHeadBufferPosition().row]
