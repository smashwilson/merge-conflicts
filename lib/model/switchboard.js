'use babel'

import {Emitter} from 'atom'

export default class Switchboard {

  constructor () {
    this.emitter = new Emitter()
  }

  onDidResolveConflict (callback) {
    return this.emitter.on('did-resolve-conflict', callback)
  }

  didResolveConflict (event) {
    return this.emitter.emit('did-resolve-conflict', event)
  }

  onDidResolveFile (callback) {
    return this.emitter.on('did-resolve-file', callback)
  }

  didResolveFile (event) {
    return this.emitter.emit('did-resolve-file', event)
  }

  onDidQuitConflictResolution (callback) {
    return this.emitter.on('did-quit-conflict-resolution', callback)
  }

  didQuitConflictResolution (event) {
    return this.emitter.emit('did-quit-conflict-resolution', event)
  }

  onDidCompleteConflictResolution (callback) {
    return this.emitter.on('did-complete-conflict-resolution', callback)
  }

  didCompleteConflictResolution (event) {
    return this.emitter.emit('did-complete-conflict-resolution', event)
  }

}
