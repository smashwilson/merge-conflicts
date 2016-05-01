'use babel'
/** @jsx etch.dom */

import etch from 'etch'
import {CompositeDisposable} from 'atom'

import {ResolverView} from './resolver-view'
import {handleErr} from './error-view'

export default class MergeView {

  constructor (merge) {
    this.merge = merge
    this.subs = new CompositeDisposable()

    this.installListeners()

    etch.initialize(this)
  }

  installListeners() {
    this.subs.add(merge.onDidResolveConflict(() => etch.update(this)))
  }

  render () {
    return (
      <div className="merge-conflicts tool-panel panel-bottom padded clearfix">
        <div className="panel-heading">
          Conflicts
          <span id="mv-hide" className="pull-right icon icon-fold">Hide</span>
          <span id="mv-show" className="pull-right icon icon-unfold">Show</span>
        </div>
        <div className="body">
          <div className="conflict-list">
            <ul id="mv-conflict-list" className="block list-group">
              {this.renderConflicts()}
            </ul>
          </div>
          <div className="footer block pull-right">
            <button className="btn btn-sm">Quit</button>
          </div>
        </div>
      </div>
    )
  }

  renderConflicts() {
    return this.merge.entries.map((entry) => {
      let resolveButton = null
      if (entry.readyToResolve()) {
        resolveButton = (
          <button className="btn btn-xs btn-success inline-block-tight stage-ready">
            {this.merge.context.resolveText}
          </button>
        )
      }

      return (
        <li className="list-item navigate" data-path={entry.path}>
          <span className="inline-block icon icon-diff-modified status-modified path">
            {entry.path}
          </span>
          <div className="pull-right">

            <span className="inline-block icon icon-dash staged">
              {entry.message}
            </span>
            <progress className="inline-block" max={entry.totalConflictCount} value={entry.resolvedConflictCount} />
            <span className="inline-block icon icon-dash staged" />
          </div>
        </li>
      )
    })
  }

  update () {
    return etch.update(this)
  }

  async destroy () {
    this.subs.dispose()

    await etch.destroy(this)
  }

}
