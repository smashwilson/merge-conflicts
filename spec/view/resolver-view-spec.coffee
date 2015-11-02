{ResolverView} = require '../../lib/view/resolver-view'

{GitBridge} = require '../../lib/git-bridge'
util = require '../util'

describe 'ResolverView', ->
  [view, fakeEditor, pkg] = []

  state =
    repo:
      getWorkingDirectory: -> "/fake/gitroot/"
      relativize: (filepath) -> filepath["/fake/gitroot/".length..]
      repo:
        add: (filepath) ->

  beforeEach ->
    pkg = util.pkgEmitter()
    fakeEditor = {
      isModified: -> true
      getURI: -> '/fake/gitroot/lib/file1.txt'
      save: ->
      onDidSave: ->
    }

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

    view = new ResolverView(fakeEditor, state, pkg)

  it 'begins needing both saving and staging', ->
    view.refresh()
    expect(view.actionText.text()).toBe('Save and stage')

  it 'shows if the file only needs staged', ->
    fakeEditor.isModified = -> false
    view.refresh()
    expect(view.actionText.text()).toBe('Stage')

  it 'saves and stages the file', ->
    p = null
    state.repo.repo.add = (filepath) -> p = filepath

    GitBridge.process = ({command, args, options, stdout, exit}) ->
      if 'status' in args
        stdout('M  lib/file1.txt')
        exit(0)
      { process: { on: (err) -> } }

    spyOn(fakeEditor, 'save')

    view.resolve()
    expect(fakeEditor.save).toHaveBeenCalled()
    expect(p).toBe('lib/file1.txt')
