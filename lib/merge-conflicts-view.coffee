{$, View} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'

GitBridge = require './git-bridge'
ConflictMarker = require './conflict-marker'

module.exports =
class MergeConflictsView extends View
  @content: (conflicts) ->
    @div class: 'merge-conflicts tool-panel panel-bottom padded', =>
      @div class: 'panel-heading', =>
        @text 'Conflicts'
        @button class: 'btn pull-right', 'Hide'
      @ul class: 'list-group', outlet: 'pathList', =>
        for p in conflicts
          @li click: 'navigate', class: 'list-item status-modified navigate', =>
            @span class: 'inline-block icon icon-diff-modified path', p
            @div class: 'pull-right', =>
              @span class: 'inline-block text-subtle', "modified by both"
              @progress class: 'inline-block', max: 100, value: 0

  initialize: (@conflicts) ->
    atom.on 'merge-conflicts:resolved', (event) =>
      p = path.relative atom.project.getPath(), event.file
      progress = @pathList.find("li:contains('#{p}') progress")[0]
      progress.max = event.total
      progress.value = event.resolved

  navigate: (event, element) ->
    p = element.find(".path").text()
    atom.workspace.open(p)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  @detect: ->
    return unless atom.project.getRepo()
    root = atom.project.getRootDirectory().getRealPathSync()
    GitBridge.conflictsIn root, (conflicts) ->
      if conflicts
        view = new MergeConflictsView(conflicts)
        atom.workspaceView.appendToBottom(view)

        atom.workspaceView.eachEditorView (view) ->
          if view.attached and view.getPane()?
            MergeConflictsView.markConflictsIn conflicts, view

  @markConflictsIn: (conflicts, editorView) ->
    return unless conflicts

    editor = editorView.getEditor()
    p = editor.getPath()
    rel = path.relative atom.project.getPath(), p
    return unless _.contains(conflicts, rel)

    new ConflictMarker(editorView)
