###
Handles the management and dispatching of nodules.
###

{spawn} = require 'child_process'
datastore = require './datastore.coffee'
logger = require './logger.coffee'

class Nodule
  constructor: (@data) ->
    @process = null
  
  isRunning: -> @process?
  
  getPID: -> @process?.pid
  
  start: ->
    return if @isRunning()
    throw new Error 'one argument needed' if @data.arguments.length == 0
    command = @data.arguments[0]
    args = @data.arguments[1..]
    params = env: @data.env, cwd: @data.path
    @process = spawn command, args, params
    @process.on 'exit', =>
      @process = null
      if @data.relaunch then @start()
    @process.on 'error', (err) =>
      console.log err
      @process.kill()
      @process = null
    logger.logProcess @process, @data.path
  
  stop: ->
    @process?.removeAllListeners?()
    @process?.kill?()
    @process = null

  toJSON: ->
    dict = running: @isRunning()
    dict.pid = @process.pid if @isRunning()
    dict[key] = obj for own key, obj of @data
    return dict

class Session
  constructor: (@datastore) ->
    # create our list of nodules
    @nodules = (new Nodule data for data in @datastore.nodules)
  
  startup: ->
    for nodule in @nodules
      nodule.start() if nodule.data.autolaunch
  
  add: (req, res) ->
    try
      newData = datastore.NoduleData.load req.body
    catch error
      return res.sendJSON 400, error: error.toString()
    
    for nodule in @nodules
      if nodule.data.identifier is newData.identifier
        return res.sendJSON 409, error: 'nodule already exists'
    addedNodule = new Nodule newData
    @datastore.nodules.push newData
    @nodules.push addedNodule
    addedNodule.start() if addedNodule.data.autolaunch
    @saveWithCallback res    

  remove: (req, res) ->
    @findNodule req, res, (nodule, i) =>
      nodule.stop() if nodule.isRunning()
      @nodules.splice i, 1
      @datastore.nodules.splice i, 1
      return @saveWithCallback res

  list: (req, res) ->
    res.sendJSON 200, nodules: @nodules

  edit: (req, res) ->
    try
      newData = datastore.NoduleData.load req.body
    catch error
      return res.sendJSON 400, error: error.toString()
      
    for nodule, i in @nodules
      if nodule.data.identifier is newData.identifier
        # replace the nodule
        wasRunning = nodule.isRunning()
        nodule.stop() if wasRunning
        nodule.data = newData
        @datastore.nodules[i] = newData
        nodule.start() if wasRunning
        # save and then callback
        return @saveWithCallback res
    res.sendJSON 404, error: 'nodule not found'
  
  start: (req, res) ->
    @findNodule req, res, (nodule, i) ->
      nodule.start()
      res.sendJSON 200, {}
  
  stop: (req, res) ->
    @findNodule req, res, (nodule, i) ->
      nodule.stop()
      res.sendJSON 200, {}
  
  saveWithCallback: (res) ->
    @datastore.save (err) ->
      if err then res.sendJSON 500, error: err.toString()
      else res.sendJSON 200, {}
  
  findNodule: (req, res, cb) ->
    if typeof req.query.identifier isnt 'string'
      return res.sendJSON 400, error: 'invalid request'
    for nodule, i in @nodules
      if nodule.data.identifier is req.query.identifier
        return cb(nodule, i)
    res.sendJSON 404, error: 'nodule not found'

module.exports = Session
