###
Handles the management and dispatching of nodules.
###

{spawn} = require 'child_process'

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
    res.sendJSON 505, error: 'nyi'

  remove: (req, res) ->
    res.sendJSON 505, error: 'nyi'

  list: (req, res) ->
    res.sendJSON 505, error: 'nyi'

  edit: (req, res) ->
    res.sendJSON 505, error: 'nyi'

module.exports = Session
