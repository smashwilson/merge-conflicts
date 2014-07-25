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

module.exports = Side: Side, OurSide: OurSide, TheirSide: TheirSide
