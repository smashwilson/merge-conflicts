{View} = require 'atom'
GitBridge = require './git-bridge'

module.exports =
class ResolverView extends View

  @content: (editor) ->
    @div class: 'overlay from-top resolver', =>
      @div class: 'block text-highlight', 'File complete'
      @div class: 'pull-right', =>
        @div class: 'block save', =>
          @button class: 'btn inline-block', click: 'save', 'Save'
          @span class: 'text-success icon icon-check'
          @span class: 'text-subtle icon icon-dash'
        @div class: 'block stage', =>
          @button class: 'btn inline-block', click: 'stage', 'Stage'
          @span class: 'text-success icon icon-check'
          @span class: 'text-subtle icon icon-dash'

  initialize: (@editor) ->
    @staged = false

  refresh: ->
    if @editor.isModified()
      @addClass 'save-needed'
    else
      @removeClass 'save-needed'

    if not @staged
      @addClass 'stage-needed'
    else
      @removeClass 'stage-needed'

  save: -> @editor.save()

  stage: ->
    GitBridge.add @editor.getUri(), =>
      @staged = true
      @refresh()
