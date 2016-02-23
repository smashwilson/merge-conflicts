path = require 'path'

class MergeState

  constructor: (@conflicts, @context, @isRebase) ->

  conflictPaths: -> c.path for c in @conflicts

  reread: (callback) ->
    @context.readConflicts()
    .then (@conflicts) =>
      callback(null, this)
    .catch (err) =>
      callback(err, this)

  isEmpty: -> @conflicts.length is 0

  relativize: (filePath) -> @context.workingDirectory.relativize filePath

  join: (relativePath) -> path.join @context.workingDirPath, relativePath

  @read: (context, callback) ->
    isr = context.isRebasing()
    context.readConflicts()
    .then (cs) ->
      callback(null, new MergeState(cs, context, isr))
    .catch (err) ->
      callback(err, null)

module.exports =
  MergeState: MergeState
