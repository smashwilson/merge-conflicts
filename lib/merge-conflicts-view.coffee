{View} = require 'atom'
GitBridge = require './git-bridge'

module.exports =
class MergeConflictsView extends View
  @content: (conflicts) ->
    @div class: 'merge-conflicts tool-panel panel-bottom padded', =>
      @div class: 'panel-heading', =>
        @text 'Conflicts'
        @button class: 'btn pull-right', 'Hide'
      @ul class: 'list-group', =>
        conflicts.forEach (path) =>
          @li click: 'navigate', class: 'list-item status-modified navigate', =>
            @span class: 'inline-block icon icon-diff-modified path', path
            @span class: 'text-subtle', "modified by both"


  initialize: (@conflicts) ->

  navigate: (event, element) ->
    path = element.find(".path").text()
    atom.workspace.open(path)

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
