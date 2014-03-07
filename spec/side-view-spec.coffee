SideView = require '../lib/side-view'

describe 'SideView', ->

  side = null
  view = null
  line = null

  beforeEach ->
    line = {}
    side = {
      klass: -> 'klass',
      site: -> 99,
      description: -> '',
      lines: -> [line]
    }
    view = new SideView(side)

  it 'triggers conflict resolution', ->
    side.resolve = -> null
    spyOn(side, "resolve")

    view.useMe()

    expect(side.resolve).toHaveBeenCalled()

  describe 'when chosen as the resolution', ->

    beforeEach ->
      side.wasChosen = -> true
      line.addClass = -> null

    it 'adds the "resolved" class'
    it 'deletes the marker line'

  describe 'when not chosen as the resolution', ->

    beforeEach ->
      side.wasChosen = -> true

    it 'deletes its hunks lines'
    it ''
