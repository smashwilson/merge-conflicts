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

  it "parses itself from a three-way diff marking"
  it "names the incoming changes"
  it "resolves HEAD"
