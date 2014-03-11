module.exports =
class Navigator

  constructor: (@separatorMarker)
    [@conflict, @previous, @next] = []

  linkToPrevious: (c) ->
    @previous = c
    conflict.navigator.next = @conflict
