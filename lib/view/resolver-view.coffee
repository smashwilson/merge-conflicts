{CompositeDisposable} = require 'atom'
{View} = require 'space-pen'

{handleErr} = require './error-view'

class ResolverView extends View

  @content: (editor, state, pkg) ->
    resolveText = state.context.resolveText
    @div class: 'overlay from-top resolver', =>
      @div class: 'block text-highlight', "We're done here"
      @div class: 'block', =>
        @div class: 'block text-info', =>
          @text "You've dealt with all of the conflicts in this file."
        @div class: 'block text-info', =>
          @span outlet: 'actionText', "Save and #{resolveText}"
          @text ' this file?'
      @div class: 'pull-left', =>
        @button class: 'btn btn-primary', click: 'dismiss', 'Maybe Later'
      @div class: 'pull-right', =>
        @button class: 'btn btn-primary', click: 'resolve', resolveText

  initialize: (@editor, @state, @pkg) ->
    @subs = new CompositeDisposable()

    @refresh()
    @subs.add @editor.onDidSave => @refresh()

    @subs.add atom.commands.add @element, 'merge-conflicts:quit', => @dismiss()

  detached: -> @subs.dispose()

  getModel: -> null

  relativePath: ->
    @state.relativize @editor.getURI()

  refresh: ->
    @state.context.isResolvedFile @relativePath()
    .then (resolved) =>
      modified = @editor.isModified()

      needsSaved = modified
      needsResolve = modified or not resolved

      unless needsSaved or needsResolve
        @hide 'fast', => @remove()
        @pkg.didResolveFile file: @editor.getURI()
        return

      resolveText = @state.context.resolveText
      if needsSaved
        @actionText.text "Save and #{resolveText.toLowerCase()}"
      else if needsResolve
        @actionText.text resolveText
    .catch handleErr

  resolve: ->
    # Suport async save implementations.
    Promise.resolve(@editor.save()).then =>
      @state.context.resolveFile @relativePath()
      .then =>
        @refresh()
      .catch handleErr

  dismiss: ->
    @hide 'fast', => @remove()

module.exports =
  ResolverView: ResolverView
