module.exports =
class Conflict
  constructor: (@mine, @yours, @parent) ->

  @parse: (hunk) ->
    [mine, yours] = ["", ""]

    invalid = (line) ->
      console.log("Invalid hunk! #{line} outside of conflict markers")

    appender = invalid

    hunk.split(/\r?\n/).forEach (line) ->
      opening = line.match(/^<{7} (\S+)$/)
      if opening
        appender = (line) -> mine += "#{line}\n"
        return

      if line.match(/^={7}$/)
        appender = (line) -> yours += "#{line}\n"
        return

      closing = line.match(/^>{7} (\S+)$/)
      if closing
        appender = invalid
        return

      # Not a marker: use the active appender
      appender(line)

    new Conflict(mine, yours, null)
