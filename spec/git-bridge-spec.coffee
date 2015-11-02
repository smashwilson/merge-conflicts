{GitBridge} = require '../lib/git-bridge'
{BufferedProcess} = require 'atom'
path = require 'path'

describe 'GitBridge', ->

  gitWorkDir = "/fake/gitroot/"

  repo =
    getWorkingDirectory: -> gitWorkDir
    relativize: (fullpath) ->
      if fullpath.startsWith gitWorkDir
        fullpath[gitWorkDir.length..]
      else
        fullpath

  beforeEach ->
    done = false
    atom.config.set('merge-conflicts.gitPath', '/usr/bin/git')

    GitBridge.locateGitAnd (err) ->
      throw err if err?
      done = true

    waitsFor -> done

  it 'checks git status for merge conflicts', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, stdout, stderr, exit}) ->
      [c, a, o] = [command, args, options]
      stdout('UU lib/file0.rb')
      stdout('AA lib/file1.rb')
      stdout('M  lib/file2.rb')
      exit(0)
      { process: { on: (callback) -> } }

    conflicts = []
    GitBridge.withConflicts repo, (err, cs) ->
      throw err if err
      conflicts = cs

    expect(conflicts).toEqual([
      { path: 'lib/file0.rb', message: 'both modified' }
      { path: 'lib/file1.rb', message: 'both added' }
    ])
    expect(c).toBe('/usr/bin/git')
    expect(a).toEqual(['status', '--porcelain'])
    expect(o).toEqual({ cwd: gitWorkDir })

  describe 'isStaged', ->

    statusMeansStaged = (status, checkPath = 'lib/file2.txt') ->
      GitBridge.process = ({stdout, exit}) ->
        stdout("#{status} lib/file2.txt")
        exit(0)
        { process: { on: (callback) -> } }

      staged = null
      GitBridge.isStaged repo, checkPath, (err, b) ->
        throw err if err
        staged = b
      staged

    it 'is true if already resolved', ->
      expect(statusMeansStaged 'M ').toBe(true)

    it 'is true if resolved as ours', ->
      expect(statusMeansStaged ' M', 'lib/file1.txt').toBe(true)

    it 'is false if still in conflict', ->
      expect(statusMeansStaged 'UU').toBe(false)

    it 'is false if resolved, but then modified', ->
      expect(statusMeansStaged 'MM').toBe(false)

  it 'checks out "our" version of a file from the index', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, exit}) ->
      [c, a, o] = [command, args, options]
      exit(0)
      { process: { on: (callback) -> } }

    called = false
    GitBridge.checkoutSide repo, 'ours', 'lib/file1.txt', (err) ->
      throw err if err
      called = true

    expect(called).toBe(true)
    expect(c).toBe('/usr/bin/git')
    expect(a).toEqual(['checkout', '--ours', 'lib/file1.txt'])
    expect(o).toEqual({ cwd: gitWorkDir })

  it 'stages changes to a file', ->
    p = ""
    repo.repo =
      add: (path) -> p = path

    called = false
    GitBridge.add repo, 'lib/file1.txt', (err) ->
      throw err if err
      called = true

    expect(called).toBe(true)
    expect(p).toBe('lib/file1.txt')

  describe 'rebase detection', ->

    withRoot = (gitDir, callback) ->
      fullDir = path.join atom.project.getDirectories()[0].getPath(), gitDir
      saved = GitBridge._repoGitDir
      GitBridge._repoGitDir = -> fullDir
      callback()
      GitBridge._repoGitDir = saved

    it 'recognizes a non-interactive rebase', ->
      withRoot 'rebasing.git', ->
        expect(GitBridge.isRebasing()).toBe(true)

    it 'recognizes an interactive rebase', ->
      withRoot 'irebasing.git', ->
        expect(GitBridge.isRebasing()).toBe(true)

    it 'returns false if not rebasing', ->
      withRoot 'merging.git', ->
        expect(GitBridge.isRebasing()).toBe(false)
