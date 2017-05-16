class MergeState

  constructor: (@conflicts, @context, @isRebase) ->
    @nResolved = 0

  conflictPaths: -> c.path for c in @conflicts

  reread: ->
    @context.readConflicts().then (@conflicts) =>

  isEmpty: -> @conflicts.length is 0

  relativize: (filePath) -> @context.workingDirectory.relativize filePath

  join: (relativePath) -> @context.joinPath(relativePath)

  showResolved: ->
      atom.notifications.addSuccess("MergeState #{@conflicts.length} #{@nResolved}")

  isResolved: -> @conflicts.length is @nResolved


  setResolved: -> @nResolved = @nResolved + 1

  @read: (context) ->
    isr = context.isRebasing()
    context.readConflicts().then (cs) ->
      new MergeState(cs, context, isr)

module.exports =
  MergeState: MergeState
