'use babel'

import MergeView from './merge-view'

import Merge from '../model/merge'

export default function registerViews (registry) {
  registry.addViewProvider(Merge, (m) => new MergeView(m).element)
}
