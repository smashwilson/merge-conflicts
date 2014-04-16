{View} = require 'atom'

class MessageView extends View

  @content: (state) ->
    @div class: 'overlay from-top merge-conflicts-message', =>
      @div class: 'panel', click: 'dismiss', =>
        @div class: "panel-heading text-#{@headingClass}", @headingText
        @div class: 'panel-body', =>
          @div class: 'block', =>
            @bodyMarkup(state)
          @div class: 'block text-subtle', 'click to dismiss'

  dismiss: ->
    @hide 'fast', => @remove()

class SuccessView extends MessageView

  @headingText = 'Merge Complete'

  @headingClass = 'success'

  @bodyMarkup: (state) ->
    @text "That's everything. "
    if state.isRebase
      @code 'git rebase --continue'
      @text ' at will to resume rebasing.'
    else
      @code 'git commit'
      @text ' at will to finish the merge.'

class NothingToMergeView extends MessageView

  @headingText = 'Nothing to Merge'

  @headingClass = 'info'

  @bodyMarkup: (state) ->
    @text 'No conflicts here!'

class MaybeLaterView extends MessageView

  @headingText = 'Maybe Later'

  @headingClass = 'warning'

  @bodyMarkup: (state) ->
    @text "Careful, you've still got conflict markers left! "
    if state.isRebase
      @code 'git rebase --abort'
    else
      @code 'git merge --abort'
    @text ' if you just want to give up on this one.'

module.exports =
  SuccessView: SuccessView,
  MaybeLaterView: MaybeLaterView,
  NothingToMergeView: NothingToMergeView
