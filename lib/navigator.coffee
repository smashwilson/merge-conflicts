module.exports =
class Navigator

  constructor: (@separatorMarker) ->
    [@conflict, @previous, @next] = [null, null, null]

  linkToPrevious: (c) ->
    @previous = c
    c.navigator.next = @conflict if c?

  nextUnresolved: ->
    current = @next
    while current? and current.isResolved()
      current = current.navigator.next
    current

  previousUnresolved: ->
    current = @previous
    while current? and current.isResolved()
      current = current.navigator.previous
    current
