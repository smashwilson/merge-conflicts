# Merge Conflicts

[![Build Status](https://travis-ci.org/smashwilson/merge-conflicts.svg?branch=master)](https://travis-ci.org/smashwilson/merge-conflicts)

Resolve your git merge conflicts in Atom!

![conflict-resolution](https://raw.github.com/smashwilson/merge-conflicts/master/docs/conflict-resolution.gif)

This package detects the conflict markers left by `git merge` and overlays a set of controls for resolving each and navigating among them. Additionally, it displays your progress through a merge.

## Features

 * Conflict resolution controls are provided for each detected conflict.
 * Choose your version, their version, combinations thereof, or arbitrary changes edited in place as a resolution.
 * Navigate to the next and previous conflicts in each file.
 * Track your progress through a merge with per-file progress bars and a file list.
 * Save and stage your resolved version of each file as it's completed.

## Events

The merge-conflicts plugin emits a number of events that other packages can subscribe to, if they wish. If you want your plugin to consume one, use code like the following:

```coffeescript
atom.on 'merge-conflicts:resolved', (event) ->
```

 * `merge-conflicts:resolved`: broadcast whenever a conflict is resolved. `event.file`: the absolute path of the file in which the conflict was found; `event.total`: the total number of conflicts in that file; `event.resolved`: the number of conflicts that are resolved, including this one.
 * `merge-conflicts:staged`: broadcast whenever a file has been completed and staged for commit. `event.file`: the absolute path of the file that was staged.
 * `merge-conflicts:quit`: broadcast when you stop merging conflicts by clicking the quit button.
 * `merge-conflicts:done`: broadcast when all conflicts in all files have successfully been resolved.

## Contributions

Contributors are welcome! I'm a big believer in [the GitHub flow](http://guides.github.com/overviews/flow/), and the [Atom package contribution guide](https://atom.io/docs/latest/contributing) is a solid resource, too.

Here's the process in a nutshell:

 1. Fork it. :fork_and_knife:
 2. Run `apm develop merge-conflicts` from your terminal to get a clone of this repo. By default, this will end up in a subdirectory of `${HOME}/github`, but you can customize it by setting `${ATOM_REPOS_HOME}`.
 3. Fix up your remotes. The convention is to have `origin` pointing to your fork and `upstream` pointing to this repo.

 Assuming you set up your username using [the local GitHub Config Convention](https://github.com/blog/180-local-github-config)

 ```bash
 $ git config --global github.user your_username
 ```

 You can set your remotes up with something like:

   ```bash
   cd ${ATOM_REPOS_HOME:-~/github}/merge-conflicts
   git remote rename origin upstream
   git remote add origin git@github.com:`git config github.user`/merge-conflicts.git
   ```

 4. Create a branch and work on your awesome bug or feature! Commit often and consider opening a pull request *before* you're done. Follow the style and conventions of existing code and be sure to write specs!
 5. Get it merged. Profit :dollar:
