express = require 'express'
proxy = require './proxy.coffee'
datastore = require './datastore.coffee'

fail = (msg) ->
  return process.stderr.write msg + '\n', -> process.exit 1

main = ->
  if process.argv.length != 4
    return fail 'Usage: coffee nodule.coffee <control port> <configuration>'
  if isNaN port = parseInt process.argv[2]
    return fail 'error: invalid control port'
  
  # load the configuration file
  configFile = process.argv[3]
  datastore.Configuration.load configFile, (err, config) ->
    return fail 'failed to load configuration file: ' + err if err
    setup port, config

setup = (port, config) ->
  app = express()
  
  app.use express.session {
    secret: 'kqsdjfmlksdhfhzirzeoibrzecrbzuzefcuercazeafxzeokwdfzeijfxcerig'
  }
    
  app.use (args...) -> authenticationEngine.bind null, config.password
  
  app.get '/proxy/setflag', proxy.setFlag
  app.get '/proxy/stop', proxy.stop
  app.get '/proxy/start', proxy.start
  
  app.listen port

authenticationEngine = (password, req, res, next) ->
  res.sendJSON = (status, obj) ->
    res.status status
    res.set 'Content-Type': 'application/json'
    res.send JSON.stringify obj
  if req.query.password isnt password
    res.sendJSON 401, error: 'missing/incorrect password'
  else next()

main()