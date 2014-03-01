MergeConflicts = require '../lib/merge-conflicts'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "MergeConflicts", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('mergeConflicts')

  describe "when the merge-conflicts:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.merge-conflicts')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'merge-conflicts:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.merge-conflicts')).toExist()
        atom.workspaceView.trigger 'merge-conflicts:toggle'
        expect(atom.workspaceView.find('.merge-conflicts')).not.toExist()
