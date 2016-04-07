"use strict";

// Git operations backed by shelling out.

let a = require("atom");
let BufferedProcess = a.BufferedProcess;
let Directory = a.Directory;
let fs = require("fs");
let path = require("path");

let common = require("./common");

exports.getContext = function (filePath) {
  return Promise.all([locateGit(), common.getActiveGitRepo(filePath)])
    .then((results) => {
      const gitCmd = results[0];
      const repoDetails = results[1];

      if (!gitCmd || !repoDetails) return null;

      const repository = repoDetails.repository;
      const priority = repoDetails.priority;
      let wd = repository.getWorkingDirectory();
      return new GitContext(repository, gitCmd, wd, priority);
    });
};

function GitContext(repository, gitCmd, workingDirPath, priority) {
  this.repository = repository;
  this.gitCmd = gitCmd;
  this.workingDirPath = workingDirPath;
  this.workingDirectory = new Directory(workingDirPath, false);
  this.runProcess = (args) => new BufferedProcess(args);
  this.priority = priority;
  this.resolveText = "Stage";
};

GitContext.prototype.readConflicts = function () {
  let conflicts = [];
  let errMessage = [];

  return new Promise((resolve, reject) => {
    let stdoutHandler = (chunk) => {
      statusCodesFrom(chunk, (index, work, p) => {
        if (index === "U" && work === "U") {
          conflicts.push({
            path: p,
            message: "both modified",
          });
        }

        if (index === "A" && work === "A") {
          conflicts.push({
            path: p,
            message: "both added",
          });
        }
      });
    };

    let stderrHandler = (line) => errMessage.push(line);

    let exitHandler = (code) => {
      if (code === 0) {
        return resolve(conflicts);
      }

      return reject(new Error(`abnormal git exit: ${code}\n${errMessage.join("\n")}`));
    };

    let proc = this.runProcess({
      command: this.gitCmd,
      args: ['status', '--porcelain'],
      options: { cwd: this.workingDirPath },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    });

    proc.process.on("error", reject);
  });
};

GitContext.prototype.isResolvedFile = function (filePath) {
  let staged = true;

  return new Promise((resolve, reject) => {
    let stdoutHandler = (chunk) => {
      statusCodesFrom(chunk, (index, work, p) => {
        if (p === filePath) {
          staged = index === "M" && work === " ";
        }
      });
    };

    let stderrHandler = console.error;

    let exitHandler = (code) => {
      if (code === 0) {
        resolve(staged);
      } else {
        reject(new Error(`git status exit: ${code}`));
      }
    };

    let proc = this.runProcess({
      command: this.gitCmd,
      args: ["status", "--porcelain", filePath],
      options: { cwd: this.workingDirPath },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    });

    proc.process.on("error", reject);
  });
};

GitContext.prototype.checkoutSide = function (sideName, filePath) {
  return new Promise((resolve, reject) => {
    let proc = this.runProcess({
      command: this.gitCmd,
      args: ["checkout", `--${sideName}`, filePath],
      options: { cwd: this.workingDirPath },
      stdout: console.log,
      stderr: console.error,
      exit: (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`git checkout exit: ${code}`));
        }
      }
    });

    proc.process.on("error", reject);
  });
};

GitContext.prototype.resolveFile = function (filePath) {
  this.repository.repo.add(filePath);
  return Promise.resolve();
};

GitContext.prototype.isRebasing = function () {
  let root = this.repository.getPath();
  if (!root) return false;

  let hasDotGitDirectory = (dirName) => {
    let fullPath = path.join(root, dirName);
    let stat = fs.statSyncNoException(fullPath);
    return stat && stat.isDirectory;
  };

  if (hasDotGitDirectory('rebase-apply')) return true;
  if (hasDotGitDirectory('rebase-merge')) return true;

  return false;
};

GitContext.prototype.mockProcess = function (handler) {
  this.runProcess = handler;
};

let locateGit = function () {
  // Use an explicitly provided path if one is available.
  let possiblePath = atom.config.get("merge-conflicts.gitPath");

  if (possiblePath) {
    return Promise.resolve(possiblePath);
  }

  let search = [
    'git', // Search the inherited execution PATH. Unreliable on Macs.
    '/usr/local/bin/git', // Homebrew
    '"%PROGRAMFILES%\\Git\\bin\\git"', // Reasonable Windows default
    '"%LOCALAPPDATA%\\Programs\\Git\\bin\\git"' // Contributed Windows path
  ];

  possiblePath = search.shift();

  return new Promise((resolve, reject) => {
    let exitHandler = (code) => {
      if (code === 0) {
        return resolve(possiblePath);
      }

      errorHandler();
    };

    let errorHandler = (err) => {
      if (err) {
        err.handle();

        // Suppress the default ENOENT handler.
        err.error.code = "NOTENOENT";
      }

      possiblePath = search.shift();

      if (!possiblePath) {
        let message = "Please set 'Git Path' correctly in the Atom settings for the Merge Conflicts"
        message += " package.";
        return reject(new Error(message));
      }

      tryPath();
    };

    let tryPath = () => {
      new BufferedProcess({
        command: possiblePath,
        args: ["--version"],
        exit: exitHandler
      }).onWillThrowError(errorHandler);
    };

    tryPath();
  });
};

let statusCodesFrom = function (chunk, handler) {
  chunk.split("\n").forEach((line) => {
    let m = line.match(/^(.)(.) (.+)$/);
    if (m) {
      let indexCode = m[1];
      let workCode = m[2];
      let p = m[3];

      handler(indexCode, workCode, p);
    }
  });
};

GitContext.prototype.joinPath = function(relativePath) {
  return path.join(this.workingDirPath, relativePath);
}
