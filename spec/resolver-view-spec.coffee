ResolverView = require '../lib/resolver-view'
GitBridge = require '../lib/git-bridge'

describe 'ResolverView', ->
  [view, editor] = []

  beforeEach ->
    editor = {
      isModified: -> true
      getUri: -> 'lib/file1.txt'
    }
    view = new ResolverView(editor)

  it 'begins needing both saving and staging', ->
    view.refresh()
    expect(view.hasClass 'save-needed').toBe(true)
    expect(view.hasClass 'stage-needed').toBe(true)

  it 'shows a check if the file is saved', ->
    editor.isModified = -> false
    view.refresh()
    expect(view.hasClass 'save-needed').toBe(false)
    expect(view.hasClass 'stage-needed').toBe(true)

  it 'stages the file', ->
    [c, a, o] = []
    GitBridge.process = ({command, args, options, exit}) ->
      [c, a, o] = [command, args, options]
      exit(0)

    view.stage()
    expect(c).toBe('git')
    expect(a).toEqual(['add', 'lib/file1.txt'])
    expect(o).toEqual({ cwd: atom.project.path })

    expect(view.hasClass 'stage-needed').toBe(false)
