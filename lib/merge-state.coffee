GitBridge = require './git-bridge'

module.exports =
class MergeState

  constructor: (@conflicts, @isRebase) ->

  reread: (callback) ->
    GitBridge.withConflicts (@conflicts) =>
      callback(this)

  isEmpty: -> @conflicts.length is 0

  @read: (callback) ->
    isr = GitBridge.isRebasing()
    GitBridge.withConflicts (cs) ->
      callback(new MergeState(cs, isr))
