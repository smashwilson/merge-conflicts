SideView = require '../lib/side-view'

describe 'SideView', ->

  it 'triggers conflict resolution', ->
    side = {
      resolve: -> null,
      klass: -> 'klass',
      site: -> 99,
      description: -> ''
    }
    spyOn(side, "resolve")

    view = new SideView(side)
    view.useMe()

    expect(side.resolve).toHaveBeenCalled()
