path = require 'path'
fs = require 'fs'

class ProcessLogger
  constructor: (@dir, @stream, @streamName) ->
    @startDate = new Date().toString()
    @stream.on 'data', (data) => @handleData data
    @stream.on 'close', => @handleClose()
    @output = null
      
  getOutputPath: -> path.join @dir, "#{@streamName}.log.#{@startDate}.txt"
    
  handleData: (data) ->
    if not @output?
      @output = fs.createWriteStream @getOutputPath()
    @output.write data
  
  handleClose: ->
    @output?.end?()
    @stream = null
  
  cancel: ->
    @handleClose()
    @output = null

exports.ProcessLogger = ProcessLogger
exports.logProcess = (task, logDir) ->
  fullPath = path.join logDir, 'log'
  createIfNotExists fullPath, (err) ->
    return console.log err if err
    new ProcessLogger fullPath, task.stdout, 'stdout'
    new ProcessLogger fullPath, task.stderr, 'stderr'

createIfNotExists = (path, cb) ->
  fs.exists path, (exists) ->
    if exists then cb null
    else
      fs.mkdir path, (err) ->
        cb err
        