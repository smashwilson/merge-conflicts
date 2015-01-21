ResolverView = require '../lib/resolver-view'
{GitBridge} = require '../lib/git-bridge'
util = require './util'

describe 'ResolverView', ->
  [view, fakeEditor, pkg] = []

  beforeEach ->
    pkg = util.pkgEmitter()
    fakeEditor = {
      isModified: -> true
      getURI: -> 'lib/file1.txt'
      save: ->
      onDidSave: ->
    }
    view = new ResolverView(fakeEditor, pkg)

    atom.config.set('merge-conflicts.gitPath', 'git')
    done = false
    GitBridge.locateGitAnd (err) ->
      throw err if err?
      done = true

    waitsFor -> done

    GitBridge.process = ({stdout, exit}) ->
      stdout('UU lib/file1.txt')
      exit(0)
      { process: { on: (err) -> } }

  it 'begins needing both saving and staging', ->
    view.refresh()
    expect(view.actionText.text()).toBe('Save and stage')

  it 'shows if the file only needs staged', ->
    fakeEditor.isModified = -> false
    view.refresh()
    expect(view.actionText.text()).toBe('Stage')

  it 'saves and stages the file', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, stdout, exit}) ->
      if 'add' in args
        [c, a, o] = [command, args, options]
        exit(0)
      if 'status' in args
        stdout('M  lib/file1.txt')
        exit(0)
      { process: { on: (err) -> } }

    spyOn(fakeEditor, 'save')

    view.resolve()
    expect(fakeEditor.save).toHaveBeenCalled()
    expect(c).toBe('git')
    expect(a).toEqual(['add', 'lib/file1.txt'])
    expect(o).toEqual({ cwd: atom.project.getRepositories()[0].getWorkingDirectory() })
