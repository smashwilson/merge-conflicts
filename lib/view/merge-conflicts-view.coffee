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

    detail = "Careful, you've still got conflict markers left!\n"
    if @state.isRebase
      detail += '"git rebase --abort"'
    else
      detail += '"git merge --abort"'
    detail += " if you just want to give up on this one."

    @finish ->
      atom.notifications.addWarning "Maybe Later",
        detail: detail
        dismissable: true

  refresh: ->
    @state.reread (err, state) =>
      return if handleErr(err)

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

      if @state.isEmpty()
        @pkg.didCompleteConflictResolution()

        detail = "That's everything. "
        if @state.isRebase
          detail += '"git rebase --continue" at will to resume rebasing.'
        else
          detail += '"git commit" at will to finish the merge.'

        @finish ->
          atom.notifications.addSuccess "All Conflicts Resolved",
            detail: detail,
            dismissable: true

  finish: (andThen) ->
    @subs.dispose()

    @hide 'fast', =>
      MergeConflictsView.instance = null
      @remove()

    andThen()

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

  @detect: (pkg) ->
    return if @instance?

    Promise.all(@contextApis.map (contextApi) => contextApi.getContext())
    .then (contexts) =>
      # filter out nulls and take the highest priority context.
      context = (
        _.filter(contexts, Boolean)
        .sort (context1, context2) => context2.priority - context1.priority
      )[0];
      unless context?
        atom.notifications.addWarning "No repository context found",
          detail: "Tip: if you have multiple projects open, open an editor in the one
            containing conflicts."
        return

      MergeState.read context, (err, state) =>
        return if handleErr(err)

        if not state.isEmpty()
          view = new MergeConflictsView(state, pkg)
          @instance = view
          atom.workspace.addBottomPanel item: view

          @instance.subs.add atom.workspace.observeTextEditors (editor) =>
            @markConflictsIn state, editor, pkg
        else
          atom.notifications.addInfo "Nothing to Merge",
            detail: "No conflicts here!",
            dismissable: true

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
