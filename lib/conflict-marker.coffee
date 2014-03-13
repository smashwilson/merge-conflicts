{$} = require 'atom'
_ = require 'underscore-plus'
Conflict = require './conflict'
SideView = require './side-view'
NavigationView = require './navigation-view'

CONFLICT_CLASSES = "conflict-line resolved ours theirs parent"
OUR_CLASSES = "conflict-line ours"
THEIR_CLASSES = "conflict-line theirs"
RESOLVED_CLASSES = "conflict-line resolved"

module.exports =
class ConflictMarker

  constructor: (@editorView) ->
    @conflicts = Conflict.all(@editorView.getEditor())
    for c in @conflicts
      new SideView(c.ours, @editorView)
      new SideView(c.theirs, @editorView)
      new NavigationView(c.navigator, @editorView)

    if @conflicts
      @editorView.addClass 'conflicted'
      @remark()
      @editorView.on "editor:display-updated", => @remark()

  ourLines: ->
    results = $()
    for c in @conflicts
      unless c.isResolved()
        results = results.add @linesForMarker(c.ours.marker)
    results

  theirLines: ->
    results = $()
    for c in @conflicts
      unless c.isResolved()
        results = results.add @linesForMarker(c.theirs.marker)
    results

  resolvedLines: ->
    results = $()
    for c in @conflicts
      if c.isResolved()
        results = results.add @linesForMarker(c.resolution.marker)
    results

  editor: -> @editorView.getEditor()

  remark: ->
    @editorView.renderedLines.removeClass(CONFLICT_CLASSES)
    @ourLines().addClass(OUR_CLASSES)
    @theirLines().addClass(THEIR_CLASSES)
    @resolvedLines().addClass(RESOLVED_CLASSES)

  linesForMarker: (marker) ->
    fromBuffer = marker.getTailBufferPosition()
    fromScreen = @editor().screenPositionForBufferPosition fromBuffer
    toBuffer = marker.getHeadBufferPosition()
    toScreen = @editor().screenPositionForBufferPosition toBuffer

    low = @editorView.getFirstVisibleScreenRow()
    high = @editorView.getLastVisibleScreenRow()

    result = $()
    for row in _.range(fromScreen.row, toScreen.row)
      if low <= row and row <= high
        result = result.add @editorView.lineElementForScreenRow row
    result
