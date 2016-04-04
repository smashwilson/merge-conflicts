class Side
  constructor: (@originalText, @ref, @marker, @refBannerMarker, @position) ->
    @conflict = null
    @isDirty = false
    @followingMarker = null

  resolve: -> @conflict.resolveAs this

  wasChosen: -> @conflict.resolution is this

  lineClass: ->
    if @wasChosen()
      'conflict-resolved'
    else if @isDirty
      'conflict-dirty'
    else
      "conflict-#{@klass()}"

  markers: -> [@marker, @refBannerMarker]

  toString: ->
    text = @originalText.replace(/[\n\r]/, ' ')
    if text.length > 20
      text = text[0..17] + "..."
    dirtyMark = if @isDirty then ' dirty' else ''
    chosenMark = if @wasChosen() then ' chosen' else ''
    "[#{@klass()}: #{text} :#{dirtyMark}#{chosenMark}]"


class OurSide extends Side

  site: -> 1

  klass: -> 'ours'

  description: -> 'our changes'

  eventName: -> 'merge-conflicts:accept-ours'

class TheirSide extends Side

  site: -> 2

  klass: -> 'theirs'

  description: -> 'their changes'

  eventName: -> 'merge-conflicts:accept-theirs'

class BaseSide extends Side

  site: -> 3

  klass: -> 'base'

  description: -> 'merged base'

  eventName: -> 'merge-conflicts:accept-base'

module.exports =
  Side: Side
  OurSide: OurSide
  TheirSide: TheirSide
  BaseSide: BaseSide
