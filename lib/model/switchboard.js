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
