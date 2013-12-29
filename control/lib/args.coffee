path = require 'path'
fs = require 'fs'

class NoduleArgs
  constructor: (argv) ->
    # process the easy part
    throw 'not enough arguments' if argv.length < 4
    @path = path.resolve argv[0]
    @identifier = argv[1]
    throw 'invalid port' if isNaN @port = parseInt(argv[2])
    index = argv.indexOf '--args'
    throw '--args must exist' if index < 0
    @arguments = argv[index + 1..]
    @urls = []
    @env = {}
    @autolaunch = false
    @relaunch = false
    
    # process the URLs and environment variables
    i = 3
    while i < index
      arg = argv[i]
      if result = /^--(.*?)=/.exec arg
        @env[result[1]] = result[2]
      else if arg is '--url'
        throw 'missing URL' if i is index - 1
        @urls.push argv[++i]
      else if arg is '--autolaunch'
        @autolaunch = true
      else if arg is '--autorelaunch'
        @relaunch = true
      else throw 'unknown argument: ' + arg
      i++
    
    @resolveExec()
  
  resolveExec: ->
    return if fs.existsSync @arguments[0]
    paths = process.env.PATH.split ':'
    for aPath in paths
      thePath = path.join aPath, @arguments[0]
      if fs.existsSync thePath
        return @arguments[0] = thePath
  
  @usage: ->
    str = '<path> <identifier> <port> [--envvar=envval, ...]\n' +
          '       [--url x, ...] [--autolaunch] [--autorelaunch] --args <args>'
    return str

exports.NoduleArgs = NoduleArgs;
