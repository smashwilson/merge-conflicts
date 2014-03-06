{$, View} = require 'atom'
GitBridge = require './git-bridge'
Conflict = require './conflict'
SideView = require './conflict-view'

module.exports =
class MergeConflictsView extends View
  @content: (conflicts) ->
    @div class: 'merge-conflicts tool-panel panel-bottom padded', =>
      @div class: 'panel-heading', =>
        @text 'Conflicts'
        @button class: 'btn pull-right', click: 'conflict', 'Hide'
      @ul class: 'list-group', =>
        for path in conflicts
          @li click: 'navigate', class: 'list-item status-modified navigate', =>
            @span class: 'inline-block icon icon-diff-modified path', path
            @span class: 'text-subtle', "modified by both"

  initialize: (@conflicts) ->

  navigate: (event, element) ->
    path = element.find(".path").text()
    atom.workspace.open(path)

  conflict: (event, element) ->
    view = atom.workspaceView.getActiveView()
    for c in Conflict.all(view)
      oursView = new SideView(c.ours)
      c.ours.lines.addClass("conflict-line ours")
      oursView.offset(left: 0, top: c.ours.marker.position().top)
      oursView.height(c.ours.marker.height())
      oursView.css("position", "absolute");
      oursView.appendTo(view.find(".overlayer"))

      theirsView = new SideView(c.theirs)
      c.theirs.lines.addClass("conflict-line theirs")
      theirsView.offset(left: 0, top: c.theirs.marker.position().top)
      theirsView.height(c.theirs.marker.height())
      theirsView.css("position", "absolute");
      theirsView.appendTo(view.find(".overlayer"))

      console.log "replaced!"

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
