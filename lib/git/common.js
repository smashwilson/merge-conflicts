"use strict";

// Utilities shared among git backends.

exports.getActiveRepo = function (filePath) {
  let dirs = atom.project.getDirectories();
  let repos = atom.project.getRepositories();
  for (let i = 0; i < dirs.length; i++) {
    let d = dirs[i];
    if (d.contains(filePath)) {
      return Promise.resolve(repos[i]);
    }
  }

  if (repos.length < 1) {
    return Promise.resolve(null);
  }

  return Promise.resolve(repos[0]);
};

let getActivePath = function () {
  let paneItem = atom.workspace.getActivePaneItem();

  if (!paneItem) return null;
  if (!paneItem.getPath) return null;

  return paneItem.getPath();
}
