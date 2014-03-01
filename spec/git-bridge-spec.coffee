GitBridge = require '../lib/git-bridge'
{BufferedProcess} = require 'atom'

describe "GitBridge", ->

  it "checks git status for merge conflicts", ->
    [c, a, o] = [null, null, null]
    GitBridge.process = ({command, args, options, stdout, stderr, exit}) ->
      [c, a, o] = [command, args, options]
      stdout("UU lib/file0.rb")
      stdout("UU lib/file1.rb")
      stdout("M  lib/file2.rb")

    conflicts = []
    GitBridge.conflictsIn ".", (path) ->
      conflicts.push(path)

    expect(conflicts).toEqual(["lib/file0.rb", "lib/file1.rb"])
    expect(c).toBe("git")
    expect(a).toEqual(["status", "--porcelain"])
    expect(o).toEqual({ cwd: "." })

  it "stages changes to a file on completion"
