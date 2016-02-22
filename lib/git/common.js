"use strict";

// Utilities shared among git backends.

exports.getActiveRepo = function (filePath) {
  atom.project.getDirectories().forEach((d) => {
    if (d.contains(filePath)) {
      return atom.project.repositoryForDirectory(d)
    }
  });

  let first = atom.project.getDirectories()[0];
  return atom.project.repositoryForDirectory(first);
};

let getActivePath = function () {
  let paneItem = atom.workspace.getActivePaneItem();

  if (!paneItem) return null;
  if (!paneItem.getPath) return null;

  return paneItem.getPath();
}
