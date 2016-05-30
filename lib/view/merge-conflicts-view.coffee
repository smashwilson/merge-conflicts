{$, View} = require 'space-pen'
{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

{MergeState} = require '../merge-state'
{ConflictedEditor} = require '../conflicted-editor'

{ResolverView} = require './resolver-view'
{handleErr} = require './error-view'

class MergeConflictsView extends View

  @instance: null
  @contextApis: []

  @content: (state, pkg) ->
    @div class: 'merge-conflicts tool-panel panel-bottom padded clearfix', =>
      @div class: 'panel-heading', =>
        @text 'Conflicts'
        @span class: 'pull-right icon icon-fold', click: 'minimize', 'Hide'
        @span class: 'pull-right icon icon-unfold', click: 'restore', 'Show'
      @div outlet: 'body', =>
        @div class: 'conflict-list', =>
          @ul class: 'block list-group', outlet: 'pathList', =>
            for {path: p, message} in state.conflicts
              @li click: 'navigate', "data-path": p, class: 'list-item navigate', =>
                @span class: 'inline-block icon icon-diff-modified status-modified path', p
                @div class: 'pull-right', =>
                  @button click: 'resolveFile', class: 'btn btn-xs btn-success inline-block-tight stage-ready', style: 'display: none', state.context.resolveText
                  @span class: 'inline-block text-subtle', message
                  @progress class: 'inline-block', max: 100, value: 0
                  @span class: 'inline-block icon icon-dash staged'
        @div class: 'footer block pull-right', =>
          @button class: 'btn btn-sm', click: 'quit', 'Quit'

  initialize: (@state, @pkg) ->
    @subs = new CompositeDisposable

    @subs.add @pkg.onDidResolveConflict (event) =>
      p = @state.relativize event.file
      found = false
      for listElement in @pathList.children()
        li = $(listElement)
        if li.data('path') is p
          found = true

          progress = li.find('progress')[0]
          progress.max = event.total
          progress.value = event.resolved

          li.find('.stage-ready').show() if event.total is event.resolved

      unless found
        console.error "Unrecognized conflict path: #{p}"

    @subs.add @pkg.onDidResolveFile => @refresh()

    @subs.add atom.commands.add @element,
      'merge-conflicts:entire-file-ours': @sideResolver('ours'),
      'merge-conflicts:entire-file-theirs': @sideResolver('theirs')

  navigate: (event, element) ->
    repoPath = element.find(".path").text()
    fullPath = @state.join repoPath
    atom.workspace.open(fullPath)

  minimize: ->
    @addClass 'minimized'
    @body.hide 'fast'

  restore: ->
    @removeClass 'minimized'
    @body.show 'fast'

  quit: ->
    @pkg.didQuitConflictResolution()
    @finish()
    @state.context.quit(@state.isRebase)

  refresh: ->
    @state.reread().catch(handleErr).then =>
      # Any files that were present, but aren't there any more, have been resolved.
      for item in @pathList.find('li')
        p = $(item).data('path')
        icon = $(item).find('.staged')
        icon.removeClass 'icon-dash icon-check text-success'
        if _.contains @state.conflictPaths(), p
          icon.addClass 'icon-dash'
        else
          icon.addClass 'icon-check text-success'
          @pathList.find("li[data-path='#{p}'] .stage-ready").hide()

      return unless @state.isEmpty()
      @pkg.didCompleteConflictResolution()
      @finish()
      @state.context.complete(@state.isRebase)

  finish: ->
    @subs.dispose()
    @hide 'fast', =>
      MergeConflictsView.instance = null
      @remove()

  sideResolver: (side) ->
    (event) =>
      p = $(event.target).closest('li').data('path')
      @state.context.checkoutSide(side, p)
      .then =>
        full = @state.join p
        @pkg.didResolveConflict file: full, total: 1, resolved: 1
        atom.workspace.open p
      .catch (err) ->
        handleErr(err)

  resolveFile: (event, element) ->
    repoPath = element.closest('li').data('path')
    filePath = @state.join repoPath

    for e in atom.workspace.getTextEditors()
      e.save() if e.getPath() is filePath

    @state.context.resolveFile(repoPath)
    .then =>
      @pkg.didResolveFile file: filePath
    .catch (err) ->
      handleErr(err)

  @registerContextApi: (contextApi) ->
    @contextApis.push(contextApi)

  @showForContext: (context, pkg) ->
    if @instance
      @instance.finish()
    MergeState.read(context).then (state) =>
      return if state.isEmpty()
      @openForState(state, pkg)
    .catch handleErr

  @hideForContext: (context) ->
    return unless @instance
    return unless @instance.state.context == context
    @instance.finish()

  @detect: (pkg) ->
    return if @instance?

    Promise.all(@contextApis.map (contextApi) => contextApi.getContext())
    .then (contexts) =>
      # filter out nulls and take the highest priority context.
      Promise.all(
        _.filter(contexts, Boolean)
        .sort (context1, context2) => context2.priority - context1.priority
        .map (context) => MergeState.read context
      )
    .then (states) =>
      state = states.find (state) -> not state.isEmpty()
      unless state?
        atom.notifications.addInfo "Nothing to Merge",
          detail: "No conflicts here!",
          dismissable: true
        return
      @openForState(state, pkg)
    .catch handleErr

  @openForState: (state, pkg) ->
    view = new MergeConflictsView(state, pkg)
    @instance = view
    atom.workspace.addBottomPanel item: view

    @instance.subs.add atom.workspace.observeTextEditors (editor) =>
      @markConflictsIn state, editor, pkg

  @markConflictsIn: (state, editor, pkg) ->
    return if state.isEmpty()

    fullPath = editor.getPath()
    repoPath = state.relativize fullPath
    return unless repoPath?

    return unless _.contains state.conflictPaths(), repoPath

    e = new ConflictedEditor(state, pkg, editor)
    e.mark()


module.exports =
  MergeConflictsView: MergeConflictsView
