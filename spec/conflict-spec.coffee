Conflict = require '../lib/conflict'
{$$} = require 'atom'

describe "Conflict", ->

  asLines = (hunk) ->
    $$ ->
      @div class: 'container', =>
        for line in hunk.split /\n/
          @div class: 'line', line

  it "parses itself from a two-way diff marking", ->
    hunk = """
           <<<<<<< HEAD
           These are my changes
           =======
           These are your changes
           >>>>>>> master

           Past the end!
           """
    lines = asLines(hunk)

    c = Conflict.parse lines.find('.line').eq(0)
    expect(c.ours.marker.text()).toBe("<<<<<<< HEAD")
    expect(c.ours.lines.eq(0).text()).toBe("These are my changes")
    expect(c.ours.ref).toBe("HEAD")
    expect(c.ours.separator.text()).toBe("=======")
    expect(c.theirs.separator.text()).toBe("=======")
    expect(c.theirs.lines.eq(0).text()).toBe("These are your changes")
    expect(c.theirs.ref).toBe("master")
    expect(c.theirs.marker.text()).toBe(">>>>>>> master")
    expect(c.parent).toBeNull()

  it "finds conflict markings from a file", ->
    content = """
              This is some text before the marking.

              More text.

              <<<<<<< HEAD
              My changes
              Multi-line even
              =======
              Your changes
              >>>>>>> other-branch

              Text in between.

              <<<<<<< HEAD
              More of my changes
              =======
              More of your changes
              >>>>>>> other-branch

              Stuff at the end.
              """
    lines = asLines content

    cs = Conflict.all(lines)
    expect(cs.length).toBe(2)
    expect(cs[0].ours.lines.eq(1).text()).toBe("Multi-line even")
    expect(cs[1].theirs.lines.eq(0).text()).toBe("More of your changes")

  it "parses itself from a three-way diff marking"
  it "names the incoming changes"
  it "resolves HEAD"
