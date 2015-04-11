## 1.3.1

- Clean up all markers when conflict detection is completed or quit. [#136](https://github.com/smashwilson/merge-conflicts/pull/136)
- Handle next-unresolved or previous-unresolved navigation when conflicts exist in that direction, but all are resolved. [#135](https://github.com/smashwilson/merge-conflicts/pull/135)

## 1.3.0

- Fix more deprecation warnings. [#132](https://github.com/smashwilson/merge-conflicts/pull/132)

## 1.2.10

- Don't decorate destroyed markers. [#124](https://github.com/smashwilson/merge-conflicts/pull/124)
- Missed a fat arrow. [#125](https://github.com/smashwilson/merge-conflicts/pull/125)
- Control subscription cleanup in CoveringViews. [#123](https://github.com/smashwilson/merge-conflicts/pull/123)

## 1.2.9

- It actually works again :wink:
- Use a package-global Emitter instead of `atom.on` [#112](https://github.com/smashwilson/merge-conflicts/pull/112)
- Search additional paths for `git` on Windows [#109](https://github.com/smashwilson/merge-conflicts/pull/109), [#110](https://github.com/smashwilson/merge-conflicts/pull/110)
- Use the `TextEditor` model exclusively, rather than hacking around with a `TextEditorView`. [#108](https://github.com/smashwilson/merge-conflicts/pull/108)
- Require space-pen rather than getting `View` and `$` from Atom itself. [#105](https://github.com/smashwilson/merge-conflicts/pull/105), [#103](https://github.com/smashwilson/merge-conflicts/pull/103)
- Use new-style event subscriptions with an `Emitter` rather than using Emissary mixins. [#104](https://github.com/smashwilson/merge-conflicts/pull/104)
- Update the stylesheets to correctly target elements within the shadow DOM. [#101](https://github.com/smashwilson/merge-conflicts/pull/101)
- Use an overlay decoration rather than injecting controls into the `TextEditorView` DOM directly. [#93](https://github.com/smashwilson/merge-conflicts/pull/93)

## 1.2.8

- Deprecation cop clean sweep! [#89](https://github.com/smashwilson/merge-conflicts/pull/89)
- Search for `git` on your PATH or in common install locations if no specific path is provided. [#88](https://github.com/smashwilson/merge-conflicts/pull/88)
- Correctly reposition `SideViews` when the editor is scrolled. [#87](https://github.com/smashwilson/merge-conflicts/pull/87)
- Render `SideView` controls over the text instead of behind it. [#85](https://github.com/smashwilson/merge-conflicts/pull/87)

## 1.2.7

- Adapt to upstream `EditorView` changes.

## 1.2.6

- Remove deprecated calls to `keyBindingsMatchingElement` and `keystroke`.

## 1.2.5

- Use CSS to distinguish EditorViews instead of `instanceof`.

## 1.2.4

- Use the Decorations API to highlight lines.

## 1.2.3

- Fix a regression in detecting dirty conflict hunks.
- Highlight the cursor line within conflict hunks.
- `Resolve: Ours Then Theirs` and `Resolve: Theirs Then Ours` work properly when rebasing.
- Correct React editor style to accomodate markup changes.
- Use `Ctrl-M` keybindings across all platforms.
- Cosmetic change to the error view.

## 1.2.2

- Work seamlessly across React and Classic editors.
- Show a friendlier error if git isn't found.

## 1.2.1

- Fix resolution context menu items being invoked from a child element.

## 1.2.0

- Consistent keymap entries on Linux, Mac and Windows.
- Detect conflicts with Windows-style line endings.
- Allow the resolver dialog to be dismissed and invoked later.
- Close the resolver dialog on quitting the merge.
- Handle "both added" conflicts.
- Travis CI!

## 1.1.0

- Special handling for conflicts encountered during a rebase.

## 1.0.0

- Identification of conflict markers.
- Superimpose conflict resolution controls.
- Resolve conflicts as either side, directly.
- Resolve conflicts by editing in place.
- Navigation among conflict markers within a file.
- Keymap entries for resolution and navigation.
- Show resolution progress for each file.
- Minify and restore the conflict panel.
- Save and stage changes for each file on completion.
