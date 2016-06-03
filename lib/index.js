'use babel'
/* globals atom */

console.log('Merge-conflicts required')

import etch from 'etch'
import {CompositeDisposable} from 'atom'

import Switchboard from './model/switchboard'
import Merge from './model/merge'
import {GitOps} from './git'
import registerViews from './view'

export default {
  config: {
    gitPath: {
      type: 'string',
      default: '',
      description: 'Absolute path to your git executable.'
    }
  },

  activate: function (state) {
    console.log('Merge-conflicts activated')

    this.subs = new CompositeDisposable()
    this.switchboard = new Switchboard()
    this.contextAPIs = [GitOps]

    // Initialize Etch and views
    etch.setScheduler(atom.views)
    registerViews(atom.views)

    this.subs.add(atom.commands.add('atom-workspace', {
      'merge-conflicts:detect': this.detect.bind(this)
    }))
  },

  deactivate: function () {
    this.subs.dispose()

    this.switchboard.destroy()
  },

  serialize: function () {
    return {}
  },

  detect: function () {
    Promise.all(this.contextAPIs.map((api) => api.getContext()))
      .then((contexts) => {
        // Filter out nulls and empty merges and take the highest-priority context.
        const ordered = contexts.filter(Boolean)
          .sort((c0, c1) => c0.priority - c1.priority)

        const promises = ordered.map((vcs) => {
          return Merge.read(this.switchboard, vcs, vcs.isRebasing())
        })

        return Promise.all(promises)
      })
      .then((merges) => {
        const merge = merges.find((m) => !m.isEmpty())

        if (!merge) {
          atom.notifications.addInfo('Nothing to Merge', {
            detail: 'No conflicts here!',
            dismissable: true
          })
          return
        }

        atom.workspace.addBottomPanel({ item: merge })
      })
  }
}
