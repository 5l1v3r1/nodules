###
Handles the management and execution of the HTTP/HTTPS proxy.
###

httpProxy = require('http-proxy')

class ProxySession
  constructor: (@nodule) ->
    @proxy = new httpProxy.RoutingProxy()
    @http = null
    @https = null
  
  setFlag: (req, res) ->
    flag = req.query.flag
    if typeof flag isnt 'string'
      res.sendJSON 400, error: 'missing/invalid flag argument'
    if not flag in ['ws', 'https', 'http_port', 'https_port']
      res.sendJSON 400, error: 'unknown flag argument'
    switch flag
      when 'ws' then

  startup: (cb) ->
    cbFunc = @serverCallback.bind this
    @http = http.createServer cbFunc
    @http.listen()
    
    if 
    cb?()

  start: (req, res) ->
    @startup (err) ->
      if err then res.sendJSON 500, error: err.toString()
      else res.sendJSON 200, {}
    

  stop: (req, res) ->
    res.sendJSON 505, error: 'nyi'

  status: (req, res) ->
    res.sendJSON 200, running: false
  
  serverCallback: (req, res) ->
    
  

module.exports = ProxySession
