{WorkspaceView} = require 'atom'

module.exports = {
  openPath: (path) ->
    fullPath = atom.project.resolve(path)

    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync(fullPath)

    atom.workspaceView.getActiveView()
}
