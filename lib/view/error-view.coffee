{View} = require 'space-pen'

class GitNotFoundErrorView extends View

  @content: (err) ->
    @div class: 'overlay from-top padded merge-conflict-error merge-conflicts-message', =>
      @div class: 'panel', =>
        @div class: 'panel-heading no-path', =>
          @code 'git'
          @text "can't be found in any of the default locations!"
        @div class: 'panel-heading wrong-path', =>
          @code 'git'
          @text "can't be found at "
          @code atom.config.get 'merge-conflicts.gitPath'
          @text '!'
        @div class: 'panel-body', =>
          @div class: 'block',
            'Please specify the correct path in the merge-conflicts package settings.'
          @div class: 'block', =>
            @button class: 'btn btn-error inline-block-tight', click: 'openSettings', 'Open Settings'
            @button class: 'btn inline-block-tight', click: 'notRightNow', 'Not Right Now'

  initialize: (err) ->
    if atom.config.get 'merge-conflicts.gitPath'
      @find('.no-path').hide()
      @find('.wrong-path').show()
    else
      @find('.no-path').show()
      @find('.wrong-path').hide()

  openSettings: ->
    atom.workspace.open 'atom://config/packages'
    @remove()

  notRightNow: ->
    @remove()

module.exports =
  handleErr: (err) ->
    return false unless err?

    if err.isGitError
      atom.workspace.addTopPanel item: new GitNotFoundErrorView(err)
    else
      atom.notifications.addError err.message
      console.error err.message, err.trace
    true
