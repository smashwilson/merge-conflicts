{BufferedProcess} = require 'atom'
fs = require 'fs'
path = require 'path'

module.exports =
class GitBridge

  # Indirection for Mockability (tm)
  @process: (args) -> new BufferedProcess(args)

  constructor: ->

  @_gitCommand: -> atom.config.get 'merge-conflicts.gitPath'

  @_repoWorkDir: -> atom.project.getRepo()?.getWorkingDirectory()

  @_repoGitDir: -> atom.project.getRepo()?.getPath()

  @_statusCodesFrom: (chunk, handler) ->
    for line in chunk.split("\n")
      m = line.match /^(.)(.) (.+)$/
      if m
        [__, indexCode, workCode, p] = m
        handler(indexCode, workCode, p)

  @withConflicts: (handler) ->
    conflicts = []

    stdoutHandler = (chunk) =>
      @_statusCodesFrom chunk, (index, work, p) ->
        if index is 'U' and work is 'U'
          conflicts.push path: p, message: 'both modified'

        if index is 'A' and work is 'A'
          conflicts.push path: p, message: 'both added'

    stderrHandler = (line) ->
      console.log("git status error: #{line}")

    exitHandler = (code) ->
      throw new Error("git status exit: #{code}") unless code is 0
      handler(conflicts)

    @process({
      command: @_gitCommand(),
      args: ['status', '--porcelain'],
      options: { cwd: @_repoWorkDir() },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    })

  @isStaged: (filepath, handler) ->
    staged = true

    stdoutHandler = (chunk) =>
      @_statusCodesFrom chunk, (index, work, p) ->
        staged = index is 'M' and work is ' ' if p is filepath

    stderrHandler = (chunk) ->
      console.log("git status error: #{chunk}")

    exitHandler = (code) ->
      throw Error("git status exit: #{code}") unless code is 0
      handler(staged)

    @process({
      command: @_gitCommand(),
      args: ['status', '--porcelain', filepath],
      options: { cwd: @_repoWorkDir() },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    })

  @checkoutSide: (sideName, filepath, callback) ->
    @process({
      command: @_gitCommand(),
      args: ['checkout', "--#{sideName}", filepath],
      options: { cwd: @_repoWorkDir() },
      stdout: (line) -> console.log line
      stderr: (line) -> console.log line
      exit: (code) ->
        throw Error("git checkout exit: #{code}") unless code is 0
        callback()
    })

  @add: (filepath, callback) ->
    @process({
      command: @_gitCommand(),
      args: ['add', filepath],
      options: { cwd: @_repoWorkDir() },
      stdout: (line) -> console.log line
      stderr: (line) -> console.log line
      exit: (code) ->
        if code is 0
          callback()
        else
          throw Error("git add failed: exit code #{code}")
    })

  @isRebasing: ->
    root = @_repoGitDir()
    return false unless root?

    rebaseDir = path.join root, 'rebase-apply'
    rebaseStat = fs.statSyncNoException(rebaseDir)
    return true if rebaseStat && rebaseStat.isDirectory()

    irebaseDir = path.join root, 'rebase-merge'
    irebaseStat = fs.statSyncNoException(irebaseDir)
    irebaseStat && irebaseStat.isDirectory()
