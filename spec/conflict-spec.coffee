Conflict = require '../lib/conflict'
{$$, WorkspaceView} = require 'atom'

describe "Conflict", ->
  [editor] = []

  loadPath = (path) ->
    fullPath = atom.project.resolve(path)

    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync(fullPath)

    editorView = atom.workspaceView.getActiveView()
    editor = editorView.getEditor()

  it "parses itself from a two-way diff marking", ->
    loadPath('single-2way-diff.txt')s
    c = Conflict.all(editor)[0]

    expect(c.ours.marker.getTailBufferPosition().toArray()).toEqual([1, 0])
    expect(c.ours.marker.getHeadBufferPosition().toArray()).toEqual([2, 0])

    expect(c.theirs.marker.getTailBufferPosition().toArray()).toEqual([3, 0])
    expect(c.theirs.marker.getHeadBufferPosition().toArray()).toEqual([4, 0])

  it "finds conflict markings from a file", ->
    loadPath('multi-2way-diff.txt')
    cs = Conflict.all(lines)

    expect(cs.length).toBe(2)
    expect(cs[0].ours.lines.eq(1).text()).toBe("Multi-line even")
    expect(cs[1].theirs.lines.eq(0).text()).toBe("More of your changes")

  describe 'sides', ->
    hunk = """
           <<<<<<< HEAD
           These are my changes
           =======
           These are your changes
           >>>>>>> master
           """
    lines = asLines(hunk)
    conflict = Conflict.parse lines.find('.line').eq(0)

    it 'retains a reference to conflict', ->
      expect(conflict.ours.conflict).toBe(conflict)
      expect(conflict.theirs.conflict).toBe(conflict)

    it 'resolves as "ours"', ->
      conflict.ours.resolve()

      expect(conflict.resolution).toBe(conflict.ours)
      expect(conflict.ours.wasChosen()).toBe(true)
      expect(conflict.theirs.wasChosen()).toBe(false)

    it 'resolves as "theirs"', ->
      conflict.theirs.resolve()

      expect(conflict.resolution).toBe(conflict.theirs)
      expect(conflict.ours.wasChosen()).toBe(false)
      expect(conflict.theirs.wasChosen()).toBe(true)

  it "parses itself from a three-way diff marking"
  it "names the incoming changes"
  it "resolves HEAD"
