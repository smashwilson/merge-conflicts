{$} = require 'atom'

class Side
  constructor: (@ref, @lines) ->

  text: -> @lines.text()

module.exports =
class Conflict
  constructor: (@ours, @theirs, @parent) ->

  @all: (editorView) ->
    editorView.find(".line:contains('<<<<<<<')").each ->
      Conflict.parse $ @

  @parse: (line) ->
    [ourLines, theirLines] = [[], []]
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
        appender = (e) -> ourLines.push e
        current = current.next('.line')
        continue

      if text.match(/^={7}$/)
        appender = (e) -> theirLines.push e
        current = current.next('.line')
        continue

      closing = text.match(/^>{7} (\S+)$/)
      if closing
        theirRef = closing[1]
        break

      # Not a marker: use the active appender
      appender(current)
      current = current.next('.line')

    ours = new Side(ourRef, ourLines)
    theirs = new Side(theirRef, theirLines)
    new Conflict(ours, theirs, null)
