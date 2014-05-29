{GitBridge} = require './git-bridge'

module.exports =
class MergeState

  constructor: (@conflicts, @isRebase) ->

  conflictPaths: -> c.path for c in @conflicts

  reread: (callback) ->
    GitBridge.withConflicts (err, @conflicts) =>
      if err?
        callback(err, null)
      else
        callback(null, this)

  isEmpty: -> @conflicts.length is 0

  @read: (callback) ->
    isr = GitBridge.isRebasing()
    GitBridge.withConflicts (err, cs) ->
      if err?
        callback(err, null)
      else
        callback(null, new MergeState(cs, isr))
