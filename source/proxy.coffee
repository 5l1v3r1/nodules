httpProxy = require 'http-proxy'
fs = require 'fs'
url = require 'url'
path = require 'path'
crypto = require 'crypto'
http = require 'http'
{loadFileFields} = require './util.coffee'

###
This class is an abstract HTTP and HTTPS proxy
with full support for SNI and WebSockets.
###
class Proxy
  constructor: ->
    @proxy = new httpProxy.RoutingProxy()
    @http = null
    @https = null
    @active = false
  
  # Getters to override
  
  getSSLConfiguration: -> throw new Error 'override this in the subclass'
  isHTTPEnabled: -> throw new Error 'override this in the subclass'
  isHTTPSEnabled: -> throw new Error 'override this in the subclass'
  isWebSocketsEnabled: -> throw new Error 'override this in the subclass'
  forwardHost: (req) -> throw new Error 'override this in the subclass'
  getPorts: -> throw new Error 'override this in the subclass'
  
  # Initialization and destruction
  
  startup: (cb) ->
    return if @active
    @active = true
    
    # create HTTP server
    if @isHTTPEnabled()
      @http = http.createServer @_serverCallback.bind this, 'http:'
    if not @isHTTPSEnabled()
      @_configureAndListen()
      return cb?()
    
    # create the HTTPS server
    sslConfig = @getSSLConfiguration()
    loadFileFields sslConfig, (err, obj) =>
      if err
        @http = null
        @active = false
        return cb? err
      @loadedSSL = obj
      opts =
        key: obj.default_key
        cert: obj.default_cert
        SNICallback: @_serverCallback.bind this, 'https:'
      @https = https.createServer opts, cbFunc
      @_configureAndListen()
      cb?()

  shutdown: (cb) ->
    @http?.close()
    @https?.close()
    @http = null
    @https = null
    @loadedSSL = null
    @active = false
    cb?()

  # Callbacks

  _serverCallback: (prot, req, res) ->
    forward = @forwardHost req, prot
    if not forward?
      res.writeHead 404, {'Content-Type': 'text/html'}
      return res.end 'No forward rule found'
    @proxy.proxyRequest req, res, forward

  _upgradeCallback: (prot, req, socket, head) ->
    forward = @forwardHost req, prot
    return socket.end() if not forward?
    @proxy.proxyWebSocketRequest req, socket, head, forward

  _sniCallback: (hostname) ->
    sniConfig = @nodules.datastore.proxy.ssl.sni
    information = sniConfig[hostname]
    return crypto.createCredentials(information).context
  
  # Configuration
  
  _configureAndListen: (server) ->
    ports = @getPorts()
    if @isWebSocketsEnabled()
      @http?.on? 'upgrade', @_upgradeCallback.bind this, 'ws:'
      @https?.on? 'upgrade', @_upgradeCallback.bind this, 'wss:'
    @https?.listen? ports.https
    @http?.listen? ports.http

###
A concrete Proxy subclass which is configured via HTTP and
which saves its configuration using the nodule datastore.
###
class ProxySession extends Proxy
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
      running: @active
      configuration: @nodule.datastore.proxy
    res.sendJSON 200, info
  
  # Overridden
  
  getSSLConfiguration: -> @nodule.datastore.proxy.ssl
  isHTTPEnabled: -> @nodule.datastore.proxy.http
  isHTTPSEnabled: -> @nodule.datastore.proxy.https
  isWebSocketsEnabled: -> @nodule.datastore.proxy.ws
  getPorts: -> @nodule.datastore.proxy.ports
  
  forwardHost: (req, usedProtocol) ->
    parsed = url.parse req.url
    reqComps = path.normalize(parsed.pathname).split '/'
    hostname = req.headers.host
    
    # iterate and find the longest subpath that contains
    # the requested path; return the port for the nodule
    # that claims ownership of that path
    matchedComps = []
    matchedHost = null
    for nodule in @nodule.datastore.nodules
      for aURL in nodule.urls
        aParsed = url.parse aURL
        aComps = path.normalize(aParsed.pathname).split '/'
        continue if aParsed.host isnt hostname
        continue if aComps.length < matchedComps.length
        continue if aParsed.protocol isnt usedProtocol
        continue if not ProxySession._isPathContained aComps, reqComps
        matchedComps = aComps
        matchedHost = port: nodule.port
    matchedHost?.host = 'localhost'
    return matchedHost
  
  @_isPathContained: (root, sub) ->
    return false if sub.length < root.length
    for comp, i in root
      return false if comp isnt sub[i]
    return true

module.exports = ProxySession
