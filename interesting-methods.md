Some interesting methods:

* `editorView.lineElementForScreenRow` returns the appropriate line `<div>` for a screen row, taking into account the rendering window.
* `editorView.updateDisplay` does the actual rendering, including (possibly) the replacement of the line elements. It also triggers the `editor:display-updated` event, after the rendered lines are updated.
* `editorView.updateRenderedLines` calculates ranges that are intact or dirty and triggers the DOM rebuild.
* `editorView.clearDirtyRanges` removes the DOM elements.
* `editorView.fillDirtyRanges` rebuilds them.
* `editorView.isScreenRowVisible` is helpful for determining if a particular row is actually visible or not.
* `editorView.htmlForScreenLine` actually constructs the line HTML. It includes the class generation, which is hardcoded at the moment.
