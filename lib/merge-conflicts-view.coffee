{$, View} = require 'space-pen'
{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'

{GitBridge} = require './git-bridge'
MergeState = require './merge-state'
ResolverView = require './resolver-view'
ConflictMarker = require './conflict-marker'
{SuccessView, MaybeLaterView, NothingToMergeView} = require './message-views'
handleErr = require './error-view'

class MergeConflictsView extends View

  instance: null

  @content: (state, pkg) ->
    @div class: 'merge-conflicts tool-panel panel-bottom padded', =>
      @div class: 'panel-heading', =>
        @text 'Conflicts'
        @span class: 'pull-right icon icon-fold', click: 'minimize', 'Hide'
        @span class: 'pull-right icon icon-unfold', click: 'restore', 'Show'
      @div outlet: 'body', =>
        @ul class: 'block list-group', outlet: 'pathList', =>
          for {path: p, message} in state.conflicts
            @li click: 'navigate', "data-path": p, class: 'list-item navigate', =>
              @span class: 'inline-block icon icon-diff-modified status-modified path', p
              @div class: 'pull-right', =>
                @button click: 'stageFile', class: 'btn btn-xs btn-success inline-block-tight stage-ready', style: 'display: none', 'Stage'
                @span class: 'inline-block text-subtle', message
                @progress class: 'inline-block', max: 100, value: 0
                @span class: 'inline-block icon icon-dash staged'
        @div class: 'block pull-right', =>
          @button class: 'btn btn-sm', click: 'quit', 'Quit'

  initialize: (@state, @pkg) ->
    @markers = []
    @subs = new CompositeDisposable

    @subs.add @pkg.onDidResolveConflict (event) =>
      p = atom.project.getRepositories()[0].relativize event.file
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

    @subs.add @pkg.onDidStageFile => @refresh()

    @subs.add atom.commands.add @element,
      'merge-conflicts:entire-file-ours': @sideResolver('ours'),
      'merge-conflicts:entire-file-theirs': @sideResolver('theirs')

  navigate: (event, element) ->
    repoPath = element.find(".path").text()
    fullPath = path.join atom.project.getRepositories()[0].getWorkingDirectory(), repoPath
    atom.workspace.open(fullPath)

  minimize: ->
    @addClass 'minimized'
    @body.hide 'fast'

  restore: ->
    @removeClass 'minimized'
    @body.show 'fast'

  quit: ->
    @pkg.didQuitConflictResolution()
    @finish(MaybeLaterView)

  refresh: ->
    @state.reread (err, state) =>
      return if handleErr(err)

      # Any files that were present, but aren't there any more, have been
      # resolved.
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
        @finish(SuccessView)

  finish: (viewClass) ->
    m.cleanup() for m in @markers
    @markers = []

    @subs.dispose()

    @hide 'fast', =>
      MergeConflictsView.instance = null
      @remove()
    atom.workspace.addTopPanel item: new viewClass(@state)

  sideResolver: (side) ->
    (event) =>
      p = $(event.target).closest('li').data('path')
      GitBridge.checkoutSide side, p, (err) =>
        return if handleErr(err)

        full = path.join atom.project.getPaths()[0], p
        @pkg.didResolveConflict file: full, total: 1, resolved: 1
        atom.workspace.open p

  stageFile: (event, element) ->
    repoPath = element.closest('li').data('path')
    filePath = path.join atom.project.getRepositories()[0].getWorkingDirectory(), repoPath

    for e in atom.workspace.getTextEditors()
      e.save() if e.getPath() is filePath

    GitBridge.add repoPath, (err) =>
      return if handleErr(err)

      @pkg.didStageFile file: filePath

  @detect: (pkg) ->
    return unless atom.project.getRepositories().length > 0
    return if @instance?

    MergeState.read (err, state) =>
      return if handleErr(err)

      if not state.isEmpty()
        view = new MergeConflictsView(state, pkg)
        @instance = view
        atom.workspace.addBottomPanel item: view

        @instance.subs.add atom.workspace.observeTextEditors (editor) =>
          marker = @markConflictsIn state, editor, pkg
          @instance.markers.push marker if marker?
      else
        atom.workspace.addTopPanel item: new NothingToMergeView(state)

  @markConflictsIn: (state, editor, pkg) ->
    return if state.isEmpty()

    fullPath = editor.getPath()
    repoPath = atom.project.getRepositories()[0].relativize fullPath
    return unless _.contains state.conflictPaths(), repoPath

    new ConflictMarker(state, editor, pkg)


module.exports =
  MergeConflictsView: MergeConflictsView
