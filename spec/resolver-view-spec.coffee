ResolverView = require '../lib/resolver-view'
{GitBridge} = require '../lib/git-bridge'

describe 'ResolverView', ->
  [view, fakeEditor] = []

  beforeEach ->
    fakeEditor = {
      isModified: -> true
      getUri: -> 'lib/file1.txt'
      save: ->
      getBuffer: -> { on: -> }
    }
    view = new ResolverView(fakeEditor)

    GitBridge._gitCommand = -> 'git'
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
    expect(o).toEqual({ cwd: atom.project.getRepo().getWorkingDirectory() })
