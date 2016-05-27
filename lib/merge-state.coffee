class MergeState

  constructor: (@conflicts, @context, @isRebase) ->

  conflictPaths: -> c.path for c in @conflicts

  reread: ->
    @context.readConflicts().then (@conflicts) =>

  isEmpty: -> @conflicts.length is 0

  relativize: (filePath) -> @context.workingDirectory.relativize filePath

  join: (relativePath) -> @context.joinPath(relativePath)

  @read: (context) ->
    isr = context.isRebasing()
    context.readConflicts().then (cs) ->
      new MergeState(cs, context, isr)

module.exports =
  MergeState: MergeState
