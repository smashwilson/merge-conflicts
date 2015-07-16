{GitBridge} = require './git-bridge'

class MergeState

  constructor: (@conflicts, @repo, @isRebase) ->

  conflictPaths: -> c.path for c in @conflicts

  reread: (callback) ->
    GitBridge.withConflicts @repo, (err, @conflicts) =>
      callback(err, this)

  isEmpty: -> @conflicts.length is 0

  @read: (repo, callback) ->
    isr = GitBridge.isRebasing()
    GitBridge.withConflicts repo, (err, cs) ->
      if err?
        callback(err, null)
      else
        callback(null, new MergeState(cs, repo, isr))

module.exports =
  MergeState: MergeState
