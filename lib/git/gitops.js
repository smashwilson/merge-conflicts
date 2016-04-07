"use strict";

// Git operations backed by nodegit.

let a = require("atom");
let Git = a.GitRepositoryAsync.Git;
let Checkout = Git.Checkout;
let Directory = a.Directory;
let common = require("./common");

exports.getContext = function (filePath) {
  let wd = null;

  return common.getActiveGitRepo(filePath)
    .then((repoDetails) => {
      if (!repoDetails) return null;

      const {repository, priority} = repoDetails;

      wd = repository.getWorkingDirectory();

      return Git.Repository.open(wd);
    })
    .then((nodegitRepo) => {
      if (!nodegitRepo) return null;

      return new GitContext(nodegitRepo, wd, priority);
    });
};

function GitContext(repository, workingDirPath, priority) {
  this.repository = repository;
  this.workingDirPath = workingDirPath;
  this.workingDirectory = new Directory(workingDirPath, false);
  this.priority = priority;
  this.resolveText = "Stage";
}

GitContext.prototype.readConflicts = function () {
  return this.repository.getStatus()
    .then((statuses) => {
      let conflicts = [];

      statuses.forEach((status) => {
        if (status.isConflicted()) {
          conflicts.push({
            path: status.path(),
            message: "both modified"
          });
        }

        // TODO: detect "both added"
      });

      return conflicts;
    })
};

GitContext.prototype.isResolvedFile = function (filePath) {
  return this.repository.getStatus()
    .then((statuses) => statuses.some((status) => {
      return status.path() === filePath && status.isModified();
    }));
};

GitContext.prototype.checkoutSide = function (sideName, filePath) {
  let strategy = 0;
  switch (sideName) {
    case "ours":
      strategy = Checkout.STRATEGY.USE_OURS;
      break;
    case "theirs":
      strategy = Checkout.STRATEGY.USE_THEIRS;
      break;
    default:
      return new Promise.reject(new Error(`Unrecognized sideName: [${sideName}]`));
  }

  return Checkout.head(this.repository, {
    checkoutStrategy: strategy
  });
};

GitContext.prototype.resolveFile = function (filePath) {
  return this.repository.index()
    .then((i) => {
      let result = i.addByPath(filePath);
      if (result === 0) {
        return Promise.resolve();
      } else {
        return Promise.reject(new Error(`Index#addByPath error code: [${result}]`));
      }
    })
};

GitContext.prototype.isRebasing = function () {
  return this.repository.isRebasing();
};

GitContext.prototype.joinPath = function(relativePath) {
  return path.join(this.workingDirPath, relativePath);
}
