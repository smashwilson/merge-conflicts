MergeConflictsView = require './merge-conflicts-view'

module.exports =
  mergeConflictsView: null

  activate: (state) ->
    @mergeConflictsView = new MergeConflictsView(state.mergeConflictsViewState)

  deactivate: ->
    @mergeConflictsView.destroy()

  serialize: ->
    mergeConflictsViewState: @mergeConflictsView.serialize()
