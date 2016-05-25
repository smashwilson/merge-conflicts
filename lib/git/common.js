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

function getActivePath() {
  let paneItem = atom.workspace.getActivePaneItem();

  if (!paneItem) return null;
  if (!paneItem.getPath) return null;

  return paneItem.getPath();
}

exports.quitContext = function (wasRebasing) {
  let detail = "Careful, you've still got conflict markers left!\n";
  if (wasRebasing)
    detail += '"git rebase --abort"';
  else
    detail += '"git merge --abort"';
  detail += " if you just want to give up on this one.";
  atom.notifications.addWarning("Maybe Later", {
    detail: detail,
    dismissable: true,
  });
}

exports.completeContext = function (wasRebasing) {
  let detail = "That's everything. ";
  if (wasRebasing)
    detail += '"git rebase --continue" at will to resume rebasing.';
  else
    detail += '"git commit" at will to finish the merge.';

  atom.notifications.addSuccess("All Conflicts Resolved", {
    detail: detail,
    dismissable: true,
  });
}
