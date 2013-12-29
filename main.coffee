express = require 'express'
datastore = require './datastore.coffee'

Session = require './nodule.coffee'
ProxySession = require './proxy.coffee'

nodule = null;
proxy = null;

fail = (msg) ->
  return process.stderr.write msg + '\n', -> process.exit 1

main = ->
  if process.argv.length isnt 4
    return fail 'Usage: coffee nodule.coffee <control port> <configuration>'
  if isNaN port = parseInt process.argv[2]
    return fail 'error: invalid control port'
  
  # load the configuration file
  configFile = process.argv[3]
  datastore.Configuration.load configFile, (err, config) ->
    return fail 'failed to load configuration file: ' + err if err
    setup port, config

setup = (port, config) ->
  nodule = new Session config
  proxy = new ProxySession nodule
  
  app = express()
  app.use addHelperMethod
  app.use authenticator
  app.use express.json()
  app.use app.router
  
  # proxy API
  app.get '/proxy/setflag', proxy.setFlag.bind proxy
  app.get '/proxy/stop', proxy.stop.bind proxy
  app.get '/proxy/start', proxy.start.bind proxy
  app.get '/proxy/status', proxy.status.bind proxy
  
  # nodule API
  app.post '/nodule/add', nodule.add.bind nodule
  app.get '/nodule/remove', nodule.remove.bind nodule
  app.get '/nodule/list', nodule.list.bind nodule
  app.post '/nodule/edit', nodule.edit.bind nodule
  app.get '/nodule/start', nodule.start.bind nodule
  app.get '/nodule/stop', nodule.stop.bind nodule
  
  # standard 404 response
  app.get '*', (req, res) ->
    res.sendJSON 404, error: 'unknown API call'
  app.post '*', (req, res) ->
    res.sendJSON 404, error: 'unknown API call'
  
  # run the server and start the nodules
  app.listen port
  nodule.startup()
  proxy.startup (err) ->
    fail 'error starting proxy: ' + err if err

# adds a sendJSON method to the response object
addHelperMethod = (req, res, next) ->
  res.sendJSON = (status, obj) ->
    res.status status
    res.set 'Content-Type': 'application/json'
    res.end (JSON.stringify obj) + '\n'
  next()

authenticator = (req, res, next) ->
  if req.query.password isnt nodule.datastore.password
    res.sendJSON 401, error: 'missing/incorrect password'
  else next()

main()