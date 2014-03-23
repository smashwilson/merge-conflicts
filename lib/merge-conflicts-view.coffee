{$, View} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'
{Subscriber} = require 'emissary'

GitBridge = require './git-bridge'
ConflictMarker = require './conflict-marker'
{SuccessView, MaybeLaterView, NothingToMergeView} = require './message-views'

module.exports =
class MergeConflictsView extends View

  Subscriber.includeInto @

  @content: (conflicts) ->
    @div class: 'merge-conflicts tool-panel panel-bottom padded', =>
      @div class: 'panel-heading', =>
        @text 'Conflicts'
        @span class: 'pull-right icon icon-fold', click: 'minimize', 'Hide'
        @span class: 'pull-right icon icon-unfold', click: 'restore', 'Show'
      @div outlet: 'body', =>
        @ul class: 'block list-group', outlet: 'pathList', =>
          for p in conflicts
            @li click: 'navigate', class: 'list-item navigate', =>
              @span class: 'inline-block icon icon-diff-modified status-modified path', p
              @div class: 'pull-right', =>
                @span class: 'inline-block text-subtle', "modified by both"
                @progress class: 'inline-block', max: 100, value: 0
                @span class: 'inline-block icon icon-dash staged'
        @div class: 'block pull-right', =>
          @button class: 'btn btn-sm', click: 'quit', 'Quit'

  initialize: (@conflicts) ->
    @markers = []
    @editorSub = null

    @subscribe atom, 'merge-conflicts:resolved', (event) =>
      p = atom.project.getRepo().relativize event.file
      progress = @pathList.find("li:contains('#{p}') progress")[0]
      if progress?
        progress.max = event.total
        progress.value = event.resolved
      else
        console.log "Unrecognized conflict path: #{p}"

    @subscribe atom, 'merge-conflicts:staged', => @refresh()

    @command 'merge-conflicts:entire-file-ours', @sideResolver('ours')
    @command 'merge-conflicts:entire-file-theirs', @sideResolver('theirs')

  navigate: (event, element) ->
    repoPath = element.find(".path").text()
    fullPath = path.join atom.project.getRepo().getWorkingDirectory(), repoPath
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
    GitBridge.withConflicts (newConflicts) =>
      # Any files that were present, but aren't there any more, have been
      # resolved.
      for item in @pathList.find('li')
        p = $(item).find('.path').text()
        icon = $(item).find('.staged')
        icon.removeClass 'icon-dash icon-check text-success'
        if _.contains newConflicts, p
          icon.addClass 'icon-dash'
        else
          icon.addClass 'icon-check text-success'

      if newConflicts.length is 0
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
    atom.workspaceView.appendToTop new viewClass

  sideResolver: (side) ->
    (event) ->
      p = $(event.target).find('.path').text()
      GitBridge.checkoutSide side, p, ->
        full = path.join atom.project.path, p
        atom.emit 'merge-conflicts:resolved', file: full, total: 1, resolved: 1
        atom.workspace.open p

  instance: null

  @detect: ->
    return unless atom.project.getRepo()
    return if @instance?

    GitBridge.withConflicts (conflicts) =>
      if conflicts.length > 0
        view = new MergeConflictsView(conflicts)
        @instance = view
        atom.workspaceView.appendToBottom(view)

        @instance.editorSub = atom.workspaceView.eachEditorView (view) =>
          if view.attached and view.getPane()?
            marker = @markConflictsIn conflicts, view
            @instance.markers.push marker if marker?
      else
        atom.workspaceView.appendToTop new NothingToMergeView

  @markConflictsIn: (conflicts, editorView) ->
    return unless conflicts

    fullPath = editorView.getEditor().getPath()
    repoPath = atom.project.getRepo().relativize fullPath
    return unless _.contains(conflicts, repoPath)

    new ConflictMarker(editorView)
