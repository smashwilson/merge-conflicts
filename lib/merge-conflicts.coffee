MergeConflictsView = require './merge-conflicts-view'

module.exports =

  activate: (state) ->
    atom.workspaceView.command "merge-conflicts:detect", ->
      MergeConflictsView.detect()

  deactivate: ->

  serialize: ->
