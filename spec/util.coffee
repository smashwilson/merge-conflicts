{WorkspaceView} = require 'atom'

module.exports = {
  openPath: (path) ->
    fullPath = atom.project.resolve(path)

    atom.workspaceView = new WorkspaceView
    atom.workspaceView.attachToDom()
    atom.workspaceView.getModel().open(fullPath)

    atom.workspaceView.getActiveView()

  rowRangeFrom: (marker) ->
    [marker.getTailBufferPosition().row, marker.getHeadBufferPosition().row]
}
