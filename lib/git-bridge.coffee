{BufferedProcess} = require 'atom'

module.exports =
class GitBridge

  # External process call implementation. Stored here for mockability (tm).
  @process = BufferedProcess

  constructor: (@repo) ->

  @conflictsIn: (baseDir, handler) ->

    stdoutHandler = (line) ->
      [_, mineCode, yoursCode, path] = line.match /^(.)(.) (.+)$/
      if mineCode is "U" and yoursCode is "U"
        handler(path)

    stderrHandler = (line) ->
      console.log("git status error: #{line}")

    exitHandler = (code) ->
      unless code is 0
        console.log("git status exit: #{code}")

    @process({
      command: "git",
      args: ["status", "--porcelain"],
      options: { "cwd": baseDir },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    })
