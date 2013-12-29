###
Handles the management and dispatching of nodules.
###

{spawn} = require 'child_process'
datastore = require './datastore.coffee'

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
      if @data.relaunch then @start()
      else @process = null
    @process.on 'error', =>
      @process.kill()
      @process = null
    # TODO: here, @process.stderr and @process.stdout should be
    # piped to output log files specific for this execution
  
  stop: ->
    @process.removeAllListeners()
    @process.kill()
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
      for nodule in @nodules
        if nodule.identifier is newData.identifier
          return res.sendJSON 409, 'nodule already exists'
      addedNodule = new Nodule newData
      @datastore.nodules.push newData
      @nodules.push addedNodule
      @datastore.save (err) ->
        if err
          res.sendJSON 500, error: err.toString()
        else
          addedNodule.start() if addedNodule.data.autolaunch
          res.sendJSON 200, {}
    catch error
      res.sendJSON 400, error: error.toString()

  remove: (req, res) ->
    if typeof req.query.identifier isnt 'string'
      return res.sendJSON 400, error: 'invalid request'
    for nodule, i in @nodules
      if nodule.data.identifier is req.query.identifier
        nodule.stop() if nodule.isRunning()
        @nodules.splice i, 1
        @datastore.nodules.splice i, 1
        return res.sendJSON 200, {}
    res.sendJSON 404, error: 'nodule not found'
      

  list: (req, res) ->
    res.sendJSON 200, nodules: @nodules

  edit: (req, res) ->
    try
      newData = datastore.NoduleData.load req.body
      for nodule, i in @nodules
        if nodule.data.identifier is newData.identifier
          nodule.stop() is nodule.isRunning()
          nodule.data = newData
          @datamanager.nodules[i] = newData
          nodule.start()
          return res.sendJSON 200, {}
      res.sendJSON 404, error: 'nodule not found'
    catch error
      res.sendJSON 400, error: error.toString()

module.exports = Session
