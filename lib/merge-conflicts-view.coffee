{$, View} = require 'atom'
_ = require 'underscore-plus'
path = require 'path'

GitBridge = require './git-bridge'
ConflictMarker = require './conflict-marker'

class MessageView extends View

  @content: ->
    @div class: 'overlay from-top merge-conflicts-message', =>
      @div class: 'panel', click: 'dismiss', =>
        @div class: "panel-heading text-#{@headingClass}", @headingText
        @div class: 'panel-body', =>
          @div class: 'block', =>
            @bodyMarkup()
          @div class: 'block text-subtle', 'click to dismiss'

  initialize: ->

  dismiss: ->
    @hide 'fast', => @remove()

class SuccessView extends MessageView

  @headingText = 'Merge Complete'

  @headingClass = 'success'

  @bodyMarkup: ->
    @text "That's everything. "
    @code 'git commit'
    @text ' at will to finish the merge.'

class MaybeLaterView extends MessageView

  @headingText = 'Maybe Later'

  @headingClass = 'warning'

  @bodyMarkup: ->
    @text "Careful, you've still got conflict markers left!"


module.exports =
class MergeConflictsView extends View
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
    atom.on 'merge-conflicts:resolved', (event) =>
      p = path.relative atom.project.getPath(), event.file
      progress = @pathList.find("li:contains('#{p}') progress")[0]
      progress.max = event.total
      progress.value = event.resolved

    atom.on 'merge-conflicts:staged', => @refresh()

    @command 'merge-conflicts:entire-file-ours', @sideResolver('ours')
    @command 'merge-conflicts:entire-file-theirs', @sideResolver('theirs')

  navigate: (event, element) ->
    p = element.find(".path").text()
    atom.workspace.open(p)

  minimize: ->
    @addClass 'minimized'
    @body.hide 'fast'

  restore: ->
    @removeClass 'minimized'
    @body.show 'fast'

  quit: -> @finish(MaybeLaterView)

  refresh: ->
    root = atom.project.getPath()
    GitBridge.conflictsIn root, (newConflicts) =>
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

      @finish(SuccessView) if newConflicts.length is 0

  finish: (viewClass) ->
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

    root = atom.project.getRootDirectory().getRealPathSync()
    GitBridge.conflictsIn root, (conflicts) =>
      if conflicts
        view = new MergeConflictsView(conflicts)
        @instance = view
        atom.workspaceView.appendToBottom(view)

        atom.workspaceView.eachEditorView (view) =>
          @markConflictsIn conflicts, view if view.attached and view.getPane()?

  @markConflictsIn: (conflicts, editorView) ->
    return unless conflicts

    editor = editorView.getEditor()
    p = editor.getPath()
    rel = path.relative atom.project.getPath(), p
    return unless _.contains(conflicts, rel)

    new ConflictMarker(editorView)
