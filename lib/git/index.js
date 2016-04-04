"use strict";

let a = require("atom");

// Feature-flagged out
if (process.env.USE_NODEGIT === 'yes' && a.GitRepositoryAsync) {
  exports.GitOps = require("./gitops");
} else {
  // nodegit is not yet available. Fall back to the shell-out version.
  exports.GitOps = require("./shellout");
}
