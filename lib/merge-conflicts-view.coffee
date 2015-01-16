{$, View} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'
{Subscriber} = require 'emissary'

{GitBridge} = require './git-bridge'
MergeState = require './merge-state'
ResolverView = require './resolver-view'
ConflictMarker = require './conflict-marker'
{SuccessView, MaybeLaterView, NothingToMergeView} = require './message-views'
handleErr = require './error-view'

module.exports =
class MergeConflictsView extends View

  instance: null
  Subscriber.includeInto this

  @content: (state) ->
    @div class: 'merge-conflicts tool-panel panel-bottom padded', =>
      @div class: 'panel-heading', =>
        @text 'Conflicts'
        @span class: 'pull-right icon icon-fold', click: 'minimize', 'Hide'
        @span class: 'pull-right icon icon-unfold', click: 'restore', 'Show'
      @div outlet: 'body', =>
        @ul class: 'block list-group', outlet: 'pathList', =>
          for {path: p, message} in state.conflicts
            @li click: 'navigate', class: 'list-item navigate', =>
              @span class: 'inline-block icon icon-diff-modified status-modified path', p
              @div class: 'pull-right', =>
                @button click: 'stageFile', class: 'btn btn-xs btn-success inline-block-tight stage-ready', style: 'display: none', 'Stage'
                @span class: 'inline-block text-subtle', message
                @progress class: 'inline-block', max: 100, value: 0
                @span class: 'inline-block icon icon-dash staged'
        @div class: 'block pull-right', =>
          @button class: 'btn btn-sm', click: 'quit', 'Quit'

  initialize: (@state) ->
    @markers = []
    @editorSub = null

    @subscribe atom, 'merge-conflicts:resolved', (event) =>
      p = atom.project.getRepositories()[0].relativize event.file
      progress = @pathList.find("li:contains('#{p}') progress")[0]
      if progress?
        progress.max = event.total
        progress.value = event.resolved
      else
        console.log "Unrecognized conflict path: #{p}"
      if event.total is event.resolved
        @pathList.find("li:contains('#{p}') .stage-ready").eq(0).show()

    @subscribe atom, 'merge-conflicts:staged', => @refresh()

    @command 'merge-conflicts:entire-file-ours', @sideResolver('ours')
    @command 'merge-conflicts:entire-file-theirs', @sideResolver('theirs')

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
    atom.emit 'merge-conflicts:quit'
    @finish(MaybeLaterView)

  refresh: ->
    @state.reread (err, state) =>
      return if handleErr(err)

      # Any files that were present, but aren't there any more, have been
      # resolved.
      for item in @pathList.find('li')
        p = $(item).find('.path').text()
        icon = $(item).find('.staged')
        icon.removeClass 'icon-dash icon-check text-success'
        if _.contains @state.conflictPaths(), p
          icon.addClass 'icon-dash'
        else
          icon.addClass 'icon-check text-success'
          @pathList.find("li:contains('#{p}') .stage-ready").eq(0).hide()

      if @state.isEmpty()
        atom.emit 'merge-conflicts:done'
        @finish(SuccessView)

  finish: (viewClass) ->
    @unsubscribe()
    m.cleanup() for m in @markers
    @markers = []
    @editorSub.off()

    @hide 'fast', =>
      MergeConflictsView.instance = null
      @remove()
    atom.workspace.addTopPanel item: viewClass(@state)

  sideResolver: (side) ->
    (event) ->
      p = $(event.target).closest('li').find('.path').text()
      GitBridge.checkoutSide side, p, (err) ->
        return if handleErr(err)

        full = path.join atom.project.getPaths()[0], p
        atom.emit 'merge-conflicts:resolved', file: full, total: 1, resolved: 1
        atom.workspace.open p

  stageFile: (event, element) ->
    repoPath = element.closest('li').find('.path').text()
    filePath = path.join atom.project.getRepositories()[0].getWorkingDirectory(), repoPath

    for e in atom.workspace.getTextEditors()
      e.save() if e.getPath() is filePath

    GitBridge.add repoPath, (err) ->
      return if handleErr(err)

      atom.emit 'merge-conflicts:staged', file: filePath

  @detect: ->
    return unless atom.project.getRepositories().length > 0
    return if @instance?

    MergeState.read (err, state) =>
      return if handleErr(err)

      if not state.isEmpty()
        view = new MergeConflictsView(state)
        @instance = view
        atom.workspace.addBottomPanel item: view

        @instance.editorSub = atom.workspace.observeTextEditors (editor) =>
          marker = @markConflictsIn state, editor
          @instance.markers.push marker if marker?
      else
        atom.workspace.addTopPanel item: new NothingToMergeView(state)

  @markConflictsIn: (state, editor) ->
    return if state.isEmpty()

    fullPath = editor.getPath()
    repoPath = atom.project.getRepositories()[0].relativize fullPath
    return unless _.contains state.conflictPaths(), repoPath

    editorView = atom.views.getView editor
    new ConflictMarker(state, editorView)
