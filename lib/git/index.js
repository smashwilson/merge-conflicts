"use strict";

try {
  require("nodegit");

  exports.GitOps = require("./gitops");
} catch (e) {
  // nodegit is not yet available. Fall back to the shell-out version.

  exports.GitOps = require("./shellout");
}
