class Side
  constructor: (@ref, @marker, @refBannerMarker, @originalText) ->
    @conflict = null

  resolve: -> @conflict.resolveAs @

  wasChosen: -> @conflict.resolution is @

class OurSide extends Side

  site: -> 1

  klass: -> 'ours'

  description: -> 'our changes'

class TheirSide extends Side

  site: -> 2

  klass: -> 'theirs'

  description: -> 'their changes'

module.exports = Side: Side, OurSide: OurSide, TheirSide: TheirSide
