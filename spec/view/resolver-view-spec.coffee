{ResolverView} = require '../../lib/view/resolver-view'

{GitOps} = require '../../lib/git'
util = require '../util'

describe 'ResolverView', ->
  [view, fakeEditor, pkg] = []

  state =
    context:
      isResolvedFile: -> Promise.resolve false
      resolveFile: ->
      resolveText: "Stage"
    relativize: (filepath) -> filepath["/fake/gitroot/".length..]

  beforeEach ->
    pkg = util.pkgEmitter()
    fakeEditor = {
      isModified: -> true
      getURI: -> '/fake/gitroot/lib/file1.txt'
      save: ->
      onDidSave: ->
    }

    view = new ResolverView(fakeEditor, state, pkg)

  it 'begins needing both saving and staging', ->
    waitsForPromise -> view.refresh()
    runs -> expect(view.actionText.text()).toBe('Save and stage')

  it 'shows if the file only needs staged', ->
    fakeEditor.isModified = -> false
    waitsForPromise -> view.refresh()
    runs -> expect(view.actionText.text()).toBe('Stage')

  it 'saves and stages the file', ->
    p = null
    state.context.resolveFile = (filepath) ->
      p = filepath
      Promise.resolve()

    spyOn(fakeEditor, 'save')

    waitsForPromise -> view.resolve()

    runs ->
      expect(fakeEditor.save).toHaveBeenCalled()
      expect(p).toBe('lib/file1.txt')
