GitOps = require '../lib/git/shellout'
{BufferedProcess} = require 'atom'
path = require 'path'

describe 'GitBridge', ->

  gitWorkDir = "/fake/gitroot/"

  [context] = []

  beforeEach ->
    atom.config.set('merge-conflicts.gitPath', '/usr/bin/git')

    waitsForPromise ->
      GitOps.getGitContext()
      .then (c) ->
        context = c
        context.workingDirPath = gitWorkDir

  it 'checks git status for merge conflicts', ->
    [c, a, o] = []
    context.mockProcess ({command, args, options, stdout, stderr, exit}) ->
      [c, a, o] = [command, args, options]
      stdout('UU lib/file0.rb')
      stdout('AA lib/file1.rb')
      stdout('M  lib/file2.rb')
      exit(0)
      { process: { on: (callback) -> } }

    conflicts = []
    waitsForPromise ->
      context.readConflicts()
      .then (cs) ->
        conflicts = cs
      .catch (e) ->
        throw e

    runs ->
      expect(conflicts).toEqual([
        { path: 'lib/file0.rb', message: 'both modified' }
        { path: 'lib/file1.rb', message: 'both added' }
      ])
      expect(c).toBe('/usr/bin/git')
      expect(a).toEqual(['status', '--porcelain'])
      expect(o).toEqual({ cwd: gitWorkDir })

  describe 'isStaged', ->

    statusMeansStaged = (status, checkPath = 'lib/file2.txt') ->
      context.mockProcess ({stdout, exit}) ->
        stdout("#{status} lib/file2.txt")
        exit(0)
        { process: { on: (callback) -> } }

      context.isStaged(checkPath)

    it 'is true if already resolved', ->
      waitsForPromise -> statusMeansStaged('M ').then (s) -> expect(s).toBe(true)

    it 'is true if resolved as ours', ->
      waitsForPromise -> statusMeansStaged(' M', 'lib/file1.txt').then (s) -> expect(s).toBe(true)

    it 'is false if still in conflict', ->
      waitsForPromise -> statusMeansStaged('UU').then (s) -> expect(s).toBe(false)

    it 'is false if resolved, but then modified', ->
      waitsForPromise -> statusMeansStaged('MM').then (s) -> expect(s).toBe(false)

  it 'checks out "our" version of a file from the index', ->
    [c, a, o] = []
    context.mockProcess ({command, args, options, exit}) ->
      [c, a, o] = [command, args, options]
      exit(0)
      { process: { on: (callback) -> } }

    called = false
    waitsForPromise ->
      context.checkoutSide('ours', 'lib/file1.txt').then -> called = true

    runs ->
      expect(called).toBe(true)
      expect(c).toBe('/usr/bin/git')
      expect(a).toEqual(['checkout', '--ours', 'lib/file1.txt'])
      expect(o).toEqual({ cwd: gitWorkDir })

  it 'stages changes to a file', ->
    p = ""
    context.repository.repo.add = (path) -> p = path

    called = false
    waitsForPromise ->
      context.add('lib/file1.txt').then -> called = true

    runs ->
      expect(called).toBe(true)
      expect(p).toBe('lib/file1.txt')

  describe 'rebase detection', ->

    withRoot = (gitDir, callback) ->
      fullDir = path.join atom.project.getDirectories()[0].getPath(), gitDir
      saved = context.repository.getPath
      context.repository.getPath = -> fullDir
      callback()
      context.repository.getPath = saved

    it 'recognizes a non-interactive rebase', ->
      withRoot 'rebasing.git', ->
        expect(context.isRebasing()).toBe(true)

    it 'recognizes an interactive rebase', ->
      withRoot 'irebasing.git', ->
        expect(context.isRebasing()).toBe(true)

    it 'returns false if not rebasing', ->
      withRoot 'merging.git', ->
        expect(context.isRebasing()).toBe(false)
