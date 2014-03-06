{$} = require 'atom'

class Side
  constructor: (@ref, @lines, @site, @marker, @separator) ->

  text: -> @lines.text()

module.exports =
class Conflict
  constructor: (@ours, @theirs, @parent) ->

  @all: (editorView) ->
    editorView.find(".line:contains('<<<<<<<')").map ->
      Conflict.parse $ @

  @parse: (line) ->
    [ourLines, theirLines] = [$(), $()]
    [ourMarker, theirMarker, separator] = [null, null, null]
    [ourRef, theirRef] = [null, null]
    current = line

    appender = (e) =>
      console.log("Invalid hunk! #{e.text()} outside of conflict markers")
      return

    while current?
      text = current.text()

      opening = text.match(/^<{7} (\S+)$/)
      if opening
        ourRef = opening[1]
        ourMarker = current
        appender = (e) -> ourLines = ourLines.add e
        current = current.next('.line')
        continue

      if text.match(/^={7}$/)
        separator = current
        appender = (e) -> theirLines = theirLines.add e
        current = current.next('.line')
        continue

      closing = text.match(/^>{7} (\S+)$/)
      if closing
        theirMarker = current
        theirRef = closing[1]
        break

      # Not a marker: use the active appender
      appender(current)
      current = current.next('.line')

    ours = new Side(ourRef, ourLines, 1, ourMarker, separator)
    theirs = new Side(theirRef, theirLines, 2, theirMarker, separator)
    new Conflict(ours, theirs, null)
