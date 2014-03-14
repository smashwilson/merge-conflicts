class Side
  constructor: (@ref, @marker, @refBannerMarker, @originalText) ->
    @conflict = null
    @isDirty = false

  resolve: -> @conflict.resolveAs @

  wasChosen: -> @conflict.resolution is @

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
