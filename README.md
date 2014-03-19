# Merge Conflicts

Resolve your git merge conflicts in Atom!

![conflict-resolution](https://raw.github.com/smashwilson/merge-conflicts/master/docs/conflict-resolution.gif)

This package detects the conflict markers left by `git merge` and overlays a set of controls for resolving each and navigating among them. Additionally, it displays your progress through a merge.

## Events

The merge-conflicts plugin emits a number of events that other packages can subscribe to, if they wish. If you want your plugin to consume one, use code like the following:

```coffeescript
atom.on 'merge-conflicts:resolved', (event) ->
```

 * `merge-conflicts:resolved`: broadcast whenever a conflict is resolved. `event.file`: the absolute path of the file in which the conflict was found; `event.total`: the total number of conflicts in that file; `event.resolved`: the number of conflicts that are resolved, including this one.
 * `merge-conflicts:staged`: broadcast whenever a file has been completed and staged for commit. `event.file`: the absolute path of the file that was staged.

## Roadmap

These are the major features that I'd consider necessary for the package to be basically useful:

 * Identification of conflict markers. :white_check_mark:
 * Superimpose conflict resolution controls. :white_check_mark:
 * Resolve conflicts as either side, directly. :white_check_mark:
 * Resolve conflicts by editing in place. :white_check_mark:
 * Navigation among conflict markers within a file. :white_check_mark:
 * Keymap entries for resolution and navigation. :white_check_mark:
 * Show resolution progress for each file. :white_check_mark:
 * Minify and restore the conflict panel. :white_check_mark:
 * Save and stage changes for each file on completion. :white_check_mark:
