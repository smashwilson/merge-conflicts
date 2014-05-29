{BufferedProcess} = require 'atom'
fs = require 'fs'
path = require 'path'

class GitNotFoundError extends Error

  constructor: (message) ->
    super(message)

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
    errMessage = []

    stdoutHandler = (chunk) =>
      @_statusCodesFrom chunk, (index, work, p) ->
        if index is 'U' and work is 'U'
          conflicts.push path: p, message: 'both modified'

        if index is 'A' and work is 'A'
          conflicts.push path: p, message: 'both added'

    stderrHandler = (line) ->
      errMessage.push line

    exitHandler = (code) ->
      if code is 0
        handler(null, conflicts)
      else
        handler(new Error("abnormal git exit: #{code}\n" + errMessage.join("\n")), null)

    proc = @process({
      command: @_gitCommand(),
      args: ['status', '--porcelain'],
      options: { cwd: @_repoWorkDir() },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    })

    proc.process.on 'error', (err) ->
      handler(new GitNotFoundError(errMessage.join("\n")), null)

  @isStaged: (filepath, handler) ->
    staged = true

    stdoutHandler = (chunk) =>
      @_statusCodesFrom chunk, (index, work, p) ->
        staged = index is 'M' and work is ' ' if p is filepath

    stderrHandler = (chunk) ->
      console.log("git status error: #{chunk}")

    exitHandler = (code) ->
      if code is 0
        handler(null, staged)
      else
        handler(new Error("git status exit: #{code}"), null)

    proc = @process({
      command: @_gitCommand(),
      args: ['status', '--porcelain', filepath],
      options: { cwd: @_repoWorkDir() },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    })

    proc.process.on 'error', (err) ->
      handler(new GitNotFoundError, null)

  @checkoutSide: (sideName, filepath, callback) ->
    proc = @process({
      command: @_gitCommand(),
      args: ['checkout', "--#{sideName}", filepath],
      options: { cwd: @_repoWorkDir() },
      stdout: (line) -> console.log line
      stderr: (line) -> console.log line
      exit: (code) ->
        if code is 0
          callback(null)
        else
          callback(new Error("git checkout exit: #{code}"))
    })

    proc.process.on 'error', (err) ->
      callback(new GitNotFoundError)

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
          callback(new Error("git add failed: exit code #{code}"))
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

module.exports =
  GitBridge: GitBridge
  GitNotFoundError: GitNotFoundError
