class Side
  constructor: (@ref, @marker, @refBannerMarker) ->
    @conflict = null

  resolve: -> @conflict.resolveAs @

  wasChosen: -> @conflict.resolution is @

  lines: ->
    fromBuffer = @marker.getTailBufferPosition()
    fromScreen = @editor().screenPositionForBufferPosition fromBuffer
    toBuffer = @marker.getHeadBufferPosition()
    toScreen = @editor().screenPositionForBufferPosition toBuffer

    lines = @editorView().renderedLines.children('.line')
    lines.slice(fromScreen.row, toScreen.row)

  refBannerLine: ->
    position = @refBannerMarker.getTailBufferPosition()
    screen = @editor().screenPositionForBufferPosition position
    @editorView().renderedLines.children('.line').eq screen.row

  refBannerOffset: ->
    position = @refBannerMarker.getTailBufferPosition()
    @editorView().pixelPositionForBufferPosition position

class OurSide extends Side

  site: -> 1

  klass: -> 'ours'

  description: -> 'our changes'

class TheirSide extends Side

  site: -> 2

  klass: -> 'theirs'

  description: -> 'their changes'

module.exports = Side: Side, OurSide: OurSide, TheirSide: TheirSide
