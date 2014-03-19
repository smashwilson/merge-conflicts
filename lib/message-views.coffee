{View} = require 'atom'

class MessageView extends View

  @content: ->
    @div class: 'overlay from-top merge-conflicts-message', =>
      @div class: 'panel', click: 'dismiss', =>
        @div class: "panel-heading text-#{@headingClass}", @headingText
        @div class: 'panel-body', =>
          @div class: 'block', =>
            @bodyMarkup()
          @div class: 'block text-subtle', 'click to dismiss'

  initialize: ->

  dismiss: ->
    @hide 'fast', => @remove()

class SuccessView extends MessageView

  @headingText = 'Merge Complete'

  @headingClass = 'success'

  @bodyMarkup: ->
    @text "That's everything. "
    @code 'git commit'
    @text ' at will to finish the merge.'

class NothingToMergeView extends MessageView

  @headingText = 'Nothing to Merge'

  @headingClass = 'info'

  @bodyMarkup: ->
    @text 'No conflicts here!'

class MaybeLaterView extends MessageView

  @headingText = 'Maybe Later'

  @headingClass = 'warning'

  @bodyMarkup: ->
    @text "Careful, you've still got conflict markers left!"

module.exports =
  SuccessView: SuccessView,
  MaybeLayerView: MaybeLaterView,
  NothingToMergeView: NothingToMergeView
