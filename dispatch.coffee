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
