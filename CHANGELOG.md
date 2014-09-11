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
