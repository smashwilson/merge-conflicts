{BufferedProcess} = require 'atom'

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
        [__, indexCode, workCode, path] = m
        handler(indexCode, workCode, path)

  @withConflicts: (handler) ->
    conflicts = []

    stdoutHandler = (chunk) =>
      @_statusCodesFrom chunk, (index, work, path) ->
        conflicts.push path if index is 'U' and work is 'U'

    stderrHandler = (line) ->
      console.log("git status error: #{line}")

    exitHandler = (code) ->
      throw "git status exit: #{code}" unless code is 0
      handler(conflicts)

    @process({
      command: @_gitCommand(),
      args: ['status', '--porcelain'],
      options: { cwd: @_repoWorkDir() },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    })

  @isStaged: (path, handler) ->
    staged = true

    stdoutHandler = (chunk) =>
      @_statusCodesFrom chunk, (index, work, p) ->
        staged = index is 'M' and work is ' ' if p is path

    stderrHandler = (chunk) =>
      console.log("git status error: #{chunk}")

    exitHandler = (code) ->
      throw "git status exit: #{code}" unless code is 0
      handler(staged)

    @process({
      command: @_gitCommand(),
      args: ['status', '--porcelain', path],
      options: { cwd: @_repoWorkDir() },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    })

  @checkoutSide: (sideName, path, callback) ->
    @process({
      command: @_gitCommand(),
      args: ['checkout', "--#{sideName}", path],
      options: { cwd: @_repoWorkDir() },
      stdout: (line) -> console.log line
      stderr: (line) -> console.log line
      exit: (code) ->
        throw "git checkout exit: #{code}" unless code is 0
        callback()
    })

  @add: (path, callback) ->
    @process({
      command: @_gitCommand(),
      args: ['add', path],
      options: { cwd: @_repoWorkDir() },
      stdout: (line) -> console.log line
      stderr: (line) -> console.log line
      exit: (code) ->
        if code is 0
          callback()
        else
          throw "git add failed: exit code #{code}"
    })
