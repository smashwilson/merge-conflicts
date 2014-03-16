GitBridge = require '../lib/git-bridge'
{BufferedProcess} = require 'atom'

describe 'GitBridge', ->

  it 'checks git status for merge conflicts', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, stdout, stderr, exit}) ->
      [c, a, o] = [command, args, options]
      stdout('UU lib/file0.rb')
      stdout('UU lib/file1.rb')
      stdout('M  lib/file2.rb')
      exit(0)

    conflicts = []
    GitBridge.conflictsIn '.', (cs) -> conflicts = cs

    expect(conflicts).toEqual(['lib/file0.rb', 'lib/file1.rb'])
    expect(c).toBe('git')
    expect(a).toEqual(['status', '--porcelain'])
    expect(o).toEqual({ cwd: '.' })

  it 'checks out "our" version of a file from the index', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, exit}) ->
      [c, a, o] = [command, args, options]
      exit(0)

    called = false
    GitBridge.checkoutSide 'ours', 'lib/file1.txt', -> called = true

    expect(called).toBe(true)
    expect(c).toBe('git')
    expect(a).toEqual(['checkout', '--ours', 'lib/file1.txt'])
    expect(o).toEqual({ cwd: atom.project.path })

  it "stages changes to a file on completion"
