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
    throw new Error 'one argument needed' if @data.arguments.length == 0
    command = @data.arguments[0]
    args = @data.arguments[1..]
    params = env: @data.env, cwd: @data.path
    @process = spawn command, args, params
    @process.on 'exit', =>
      if @data.relaunch then @start()
      else @process = null
    # TODO: here, @process.stderr and @process.stdout should be
    # piped to output log files specific for this execution
  
  stop: ->
    @process.removeAllListeners()
    @process.kill()
    @process = null

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
    res.sendJSON 505, error: 'nyi'

  list: (req, res) ->
    res.sendJSON 505, error: 'nyi'

  edit: (req, res) ->
    res.sendJSON 505, error: 'nyi'

module.exports = Session
