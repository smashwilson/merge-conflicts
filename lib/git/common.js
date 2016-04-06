"use strict";

// Utilities shared among git backends.

exports.getActiveGitRepo = function (filePath) {
  if (!filePath) {
    filePath = getActivePath();
  }
  let dirs = atom.project.getDirectories();
  let repos = atom.project.getRepositories();
  for (let i = 0; i < dirs.length; i++) {
    let d = dirs[i];
    if (d.contains(filePath) && isGitRepo(repos[i])) {
      return Promise.resolve({
        repository: repos[i],
        priority: 3,
      });
    }
  }

  const firstGitRepo = repos.filter(isGitRepo)[0];
  return Promise.resolve(firstGitRepo == null ? null : {
    repository: firstGitRepo,
    priority: 2,
  });
};

function isGitRepo(repo) {
  return repo != null && repo.getType() === 'git';
}

let getActivePath = function () {
  let paneItem = atom.workspace.getActivePaneItem();

  if (!paneItem) return null;
  if (!paneItem.getPath) return null;

  return paneItem.getPath();
}
