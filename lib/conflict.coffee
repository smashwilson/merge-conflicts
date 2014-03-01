module.exports =
class Conflict
  constructor: (@mine, @mineRef, @yours, @yoursRef, @parent) ->

  @all: (content) ->
    hunkPattern = /<{7}[^]+?>{7}/mg
    conflicts = []

    m = hunkPattern.exec(content)
    while m?
      conflicts.push Conflict.parse(m[0])
      m = hunkPattern.exec(content)

    conflicts

  @parse: (hunk) ->
    [mine, yours] = ["", ""]
    [mineRef, yoursRef] = [null, null]

    invalid = (line) ->
      console.log("Invalid hunk! #{line} outside of conflict markers")

    appender = invalid

    for line in hunk.split(/\r?\n/)
      opening = line.match(/^<{7} (\S+)$/)
      if opening
        mineRef = opening[1]
        appender = (line) -> mine += "#{line}\n"
        continue

      if line.match(/^={7}$/)
        appender = (line) -> yours += "#{line}\n"
        continue

      closing = line.match(/^>{7} (\S+)$/)
      if closing
        yoursRef = closing[1]
        appender = invalid
        continue

      # Not a marker: use the active appender
      appender(line)

    new Conflict(mine, mineRef, yours, yoursRef, null)
