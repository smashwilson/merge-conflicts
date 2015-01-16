module.exports =
  openPath: (path, callback) ->
    waitsForPromise -> atom.workspace.open(path)

    runs ->
      callback(atom.views.getView(atom.workspace.getActivePaneItem()))

  rowRangeFrom: (marker) ->
    [marker.getTailBufferPosition().row, marker.getHeadBufferPosition().row]
