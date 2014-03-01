Conflict = require '../lib/conflict'

describe "Conflict", ->

  it "parses itself from a two-way diff marking", ->
    hunk = """
           <<<<<<< HEAD
           These are my changes
           =======
           These are your changes
           >>>>>>> master
           """
    c = Conflict.parse(hunk)
    expect(c.mine).toBe("These are my changes\n")
    expect(c.mineRef).toBe("HEAD")
    expect(c.yours).toBe("These are your changes\n")
    expect(c.yoursRef).toBe("master")
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

    cs = Conflict.all(content)
    expect(cs.length).toBe(2)
    expect(cs[0].mine).toBe("My changes\nMulti-line even\n")
    expect(cs[1].mine).toBe("More of my changes\n")

  it "parses itself from a three-way diff marking"
  it "names the incoming changes"
  it "resolves HEAD"
