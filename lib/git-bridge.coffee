{BufferedProcess} = require 'atom'

module.exports =
class GitBridge

  # Indirection for Mockability (tm)
  @process: (args) -> new BufferedProcess(args)

  constructor: (@repo) ->

  @conflictsIn: (baseDir, handler) ->
    conflicts = []

    stdoutHandler = (chunk) ->
      chunk.split("\n").forEach (line) ->
        m = line.match /^(.)(.) (.+)$/
        if m
          [_, mineCode, yoursCode, path] = m
          conflicts.push path if mineCode is "U" and yoursCode is "U"

    stderrHandler = (line) ->
      console.log("git status error: #{line}")

    exitHandler = (code) ->
      unless code is 0
        console.log("git status exit: #{code}")
      handler(conflicts)

    GitBridge.process({
      command: "git",
      args: ["status", "--porcelain"],
      options: { "cwd": baseDir },
      stdout: stdoutHandler,
      stderr: stderrHandler,
      exit: exitHandler
    })
