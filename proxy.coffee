###
Handles the management and execution of the HTTP/HTTPS proxy.
###

httpProxy = require 'http-proxy'
fs = require 'fs'

class Proxy
  constructor: ->
    @proxy = new httpProxy.RoutingProxy()
    @http = null
    @https = null
    active = false
  
  # Getters to override
  
  getSSLConfiguration: -> throw new Error 'override this in the subclass'
  isHTTPEnabled: -> throw new Error 'override this in the subclass'
  isHTTPSEnabled: -> throw new Error 'override this in the subclass'
  isWebSocketsEnabled: -> throw new Error 'override this in the subclass'
  forwardHost: (req) -> throw new Error 'override this in the subclass'
  getPorts: -> throw new Error 'override this in the subclass'
  
  # Initialization and destruction
  
  startup: (cb) ->
    return if active
    active = true
    cbFunc = @_serverCallback.bind this
    
    # create HTTP server
    if @isHTTPEnabled()
      @http = http.createServer cbFunc
    if not @isHTTPSEnabled
      @_configureAndListen()
      return cb?()
    
    # create the HTTPS server
    sslConfig = @getSSLConfiguration()
    fs.readFile sslConfig.default_key, (err, key) =>
      return @shutdown(), cb?(err) if err
      fs.readFile sslConfig.default_cert, (err, cert) =>
        return @shutdown(), cb?(err) if err
        opts =
          key: key
          cert: cert
          SNICallback: @sniCallback.bind this
        @https = https.createServer opts, cbFunc
        @_configureAndListen()
        cb?()

  shutdown: (cb) ->
    @http?.close()
    @https?.close()
    @http = null
    @https = null
    active = false
    cb?()

  # Callbacks

  _serverCallback: (req, res) ->
    forward = @forwardHost req
    @proxy.proxyRequest req, res, forward

  _upgradeCallback: (req, socket, head) ->
    forward = @forwardHost req
    @proxy.proxyWebSocketRequest req, socket, head, forward

  _sniCallback: (hostname) ->
    throw new Error 'nyi'
    
  # Configuration

  _configureAndListen: (server) ->
    ports = @getPorts()
    if @isWebSocketsEnabled()
      ugHandler = @upgradeCallback.bind this
      @http?.on? 'upgrade' upHandler
      @https?.on? 'upgrade' upHandler
    @https?.listen? ports.https
    @http?.listen? ports.http

class ProxySession extends proxy
  constructor: (@nodule) -> super()
  
  setFlag: (req, res) ->
    flag = req.query.flag
    setting = null
    
    # get the flag
    if typeof flag isnt 'string'
      return res.sendJSON 400, error: 'missing/invalid flag argument'
    if not flag in ['ws', 'http', 'https', 'http_port', 'https_port']
      return res.sendJSON 400, error: 'unknown flag argument'
    if typeof req.query.setting isnt 'string'
      return res.sendJSON 400, error: 'missing/invalid setting argument'
    
    # apply the setting value
    boolFlags = ['ws', 'http', 'https']
    proxy = @nodule.datastore.proxy
    if flag in boolFlags
      if not req.query.setting in ['true', 'false']
        return res.sendJSON 400, error: 'invalid setting argument'
      setting = req.query.setting is 'true'
      proxy[flag] = setting
    else
      if isNaN setting = parseInt req.query.setting
        return res.sendJSON 400, error: 'invalid setting argument'
      switch flag
        when 'http_port' then proxy.ports.http = setting
        when 'https_port' then proxy.ports.https = setting
        
    # save and restart
    @nodule.datastore.save (err) =>
      return res.sendJSON 500, error: err.toString() if err
      @shutdown (err) =>
        return res.sendJSON 500, error: err.toString() if err
        @start(req, res)

  start: (req, res) ->
    @startup (err) ->
      if err then res.sendJSON 500, error: err.toString()
      else res.sendJSON 200, {}
    
  stop: (req, res) ->
    @shutdown (err) ->
      if err then res.sendJSON 500, error: err.toString()
      else res.sendJSON 200, {}

  status: (req, res) ->
    info = 
      running: @active,
      configuration: @nodule.datastore.proxy
    res.sendJSON 200, info
  
  # Overridden
  
  getSSLConfiguration: -> @nodule.datastore.proxy.ssl
  isHTTPEnabled: -> @nodule.datastore.proxy.http
  isHTTPSEnabled: -> @nodule.datastore.proxy.https
  isWebSocketsEnabled: -> @nodule.datastore.proxy.ws
  getPorts: -> @nodule.datastore.proxy.ports
  
  forwardHost: (req) ->
    # perform routing logic here
    throw new Error 'nyi'
    

module.exports = ProxySession
