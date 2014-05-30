{View} = require 'atom'
{GitNotFoundError} = require './git-bridge'

class GitNotFoundErrorView extends View

  @content: (err) ->
    @div class: 'overlay from-top padded merge-conflict-error merge-conflicts-message', =>
      @div class: 'panel', =>
        @div class: "panel-heading", =>
          @code 'git'
          @text "can't be found at "
          @code atom.config.get 'merge-conflicts.gitPath'
          @text '!'
        @div class: 'panel-body', =>
          @div class: 'block',
            'Please fix the path in your settings.'
          @div class: 'block', =>
            @button class: 'btn btn-error inline-block-tight', click: 'openSettings', 'Open Settings'
            @button class: 'btn inline-block-tight', click: 'notRightNow', 'Not Right Now'

  openSettings: ->
    atom.workspace.open 'atom://config'
    @remove()

  notRightNow: ->
    @remove()

module.exports = (err) ->
  return false unless err?

  if err instanceof GitNotFoundError
    atom.workspaceView.appendToTop new GitNotFoundErrorView(err)

  console.error err
  true
