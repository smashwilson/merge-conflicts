'use babel'

import {Emitter} from 'atom'

export default class Switchboard {

  constructor () {
    this.emitter = new Emitter()
  }

  onDidResolveConflict (callback) {
    this.emitter.on('did-resolve-conflict', callback)
  }

  didResolveConflict (event) {
    this.emitter.emit('did-resolve-conflict', event)
  }

  onDidResolveFile (callback) {
    this.emitter.on('did-resolve-file', callback)
  }

  didResolveFile (event) {
    this.emitter.emit('did-resolve-file', event)
  }

  onDidQuitConflictResolution (callback) {
    this.emitter.on('did-quit-conflict-resolution', callback)
  }

  didQuitConflictResolution (event) {
    this.emitter.emit('did-quit-conflict-resolution', event)
  }

  onDidCompleteConflictResolution (callback) {
    this.emitter.on('did-complete-conflict-resolution', callback)
  }

  didCompleteConflictResolution (event) {
    this.emitter.emit('did-complete-conflict-resolution', event)
  }

}

const eventNames = [
  'didResolveConflict', 'didResolveFile', 'didQuitConflictResolution', 'didResolveConflict'
]

const subscriptionMethods = eventNames.map((name) => {
  `on${name[0].toUpperCase()}${name.slice(1)}`
})

const broadcastMethods = eventNames

function delegator (eventMethodSubset, target, switchboard) {
  var makeDelegator = (eventName, arg) => {
    return function (arg) {
      return switchboard[eventName](arg)
    }
  }

  for (eventName of eventMethodSubset) {
    target[eventName] = makeDelegator(eventName)
  }
}

export function delegateSubscriptionMethodsTo(target, switchboard) {
  delegator(subscriptionMethods, target, switchboard)
}

export function delegateBroadcastMethodsTo(target, switchboard) {
  delegator(broadcastMethods, target, switchboard)
}
