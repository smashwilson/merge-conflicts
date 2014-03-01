{View} = require 'atom'

module.exports =
class MergeConflictsView extends View
  @content: ->
    @div class: 'merge-conflicts overlay from-top', =>
      @div "The MergeConflicts package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "merge-conflicts:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "MergeConflictsView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
