'use babel'
/** @jsx etch.dom */

import etch from 'etch'
import DOMListener from 'dom-listener'
import {CompositeDisposable} from 'atom'

export default class MergeView {

  constructor (merge) {
    this.merge = merge
    this.subs = new CompositeDisposable()

    etch.initialize(this)

    this.listener = new DOMListener(this.element)

    this.installListeners()
  }

  installListeners () {
    const sb = this.merge.switchboard()
    const up = () => etch.update(this)

    this.subs.add(sb.onDidResolveConflict(up))
    this.subs.add(sb.onDidResolveFile(up))
  }

  render () {
    return (
      <div className='merge-conflicts tool-panel panel-bottom padded clearfix'>
        <div className='panel-heading'>
          Conflicts
          <span id='mv-hide' className='pull-right icon icon-fold'>Hide</span>
          <span id='mv-show' className='pull-right icon icon-unfold'>Show</span>
        </div>
        <div className='body'>
          <div className='conflict-list'>
            <ul id='mv-conflict-list' className='block list-group'>
              {this.renderConflicts()}
            </ul>
          </div>
          <div className='footer block pull-right'>
            <button className='btn btn-sm'>Quit</button>
          </div>
        </div>
      </div>
    )
  }

  renderConflicts () {
    return this.merge.mapConflictingFiles((cf) => {
      return (
        <li className='list-item navigate' data-path={cf.path}>
          <span className='inline-block icon icon-diff-modified status-modified path'>
            {cf.path}
          </span>
          <div className='pull-right'>

            <span className='inline-block icon icon-dash staged'>
              {cf.message}
            </span>
            <progress className='inline-block' max={cf.totalConflictCount()} value={cf.resolvedConflictCount()} />
            <span className='inline-block icon icon-dash staged' />
          </div>
        </li>
      )
    })
  }

  async destroy () {
    this.subs.dispose()

    await etch.destroy(this)
  }

}
