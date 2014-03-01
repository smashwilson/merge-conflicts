module.exports =
class Conflict
  constructor: (@mine, @mineRef, @yours, @yoursRef, @parent) ->

  @parse: (hunk) ->
    [mine, yours] = ["", ""]
    [mineRef, yoursRef] = [null, null]

    invalid = (line) ->
      console.log("Invalid hunk! #{line} outside of conflict markers")

    appender = invalid

    hunk.split(/\r?\n/).forEach (line) ->
      opening = line.match(/^<{7} (\S+)$/)
      if opening
        mineRef = opening[1]
        appender = (line) -> mine += "#{line}\n"
        return

      if line.match(/^={7}$/)
        appender = (line) -> yours += "#{line}\n"
        return

      closing = line.match(/^>{7} (\S+)$/)
      if closing
        yoursRef = closing[1]
        appender = invalid
        return

      # Not a marker: use the active appender
      appender(line)

    new Conflict(mine, mineRef, yours, yoursRef, null)
