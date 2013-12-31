httpProxy = require 'http-proxy'
fs = require 'fs'
url = require 'url'
path = require 'path'
crypto = require 'crypto'
http = require 'http'
https = require 'https'
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
    return cb? new Error 'already running' if @active
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
        SNICallback: @_sniCallback.bind this
      if obj.default_ca?
        opts.ca = obj.default_ca
      @https = https.createServer opts, @_serverCallback.bind this, 'https:'
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
    information = @loadedSSL.sni[hostname]
    
    # create the default credentials if this domain wasn't reg'd
    if not information?
      information = 
        cert: @loadedSSL.default_cert
        key: @loadedSSL.default_key
      information.ca = @loadedSSL.default_ca if @loadedSSL.default_ca?
    
    # create our credential context
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
class ControllableProxy extends Proxy
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
    @_saveAndRestart req, res

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
  
  setCertificate: (req, res) ->
    if typeof req.body.entry.cert != 'string'
      return res.sendJSON 400, error: 'invalid cert argument'
    if typeof req.body.entry.key != 'string'
      return res.sendJSON 400, error: 'invalid key argument'
    if req.body.entry.ca?
      if not req.body.entry.ca instanceof Array
        return res.sendJSON 400, error: 'invalid ca argument'
      for a in req.body.entry.ca
        if typeof a != 'string'
          return res.sendJSON 400, error: 'invalid ca argument'
    # register the certificate
    if req.body.domain?
      @nodule.datastore.proxy.ssl.sni[req.body.domain] = req.body.entry
    else
      @nodule.datastore.proxy.ssl.default_cert = req.body.entry.cert
      @nodule.datastore.proxy.ssl.default_key = req.body.entry.key
      if req.body.entry.ca
        @nodule.datastore.proxy.ssl.default_ca = req.body.entry.ca
      else delete @nodule.datastore.proxy.ssl.default_ca
    @_saveAndRestart req, res
  
  # Private
  
  _saveAndRestart: (req, res) ->
    @nodule.datastore.save (err) =>
      return res.sendJSON 500, error: err.toString() if err
      return res.sendJSON 200, {} if not @active
      @shutdown (err) =>
        return res.sendJSON 500, error: err.toString() if err
        @start(req, res)
  
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
    for aNodule in @nodule.nodules
      continue if not aNodule.isRunning()
      nodule = aNodule.data
      for aURL in nodule.urls
        aParsed = url.parse aURL
        aComps = path.normalize(aParsed.pathname).split '/'
        continue if aParsed.host isnt hostname
        continue if aComps.length < matchedComps.length
        continue if aParsed.protocol isnt usedProtocol
        continue if not ControllableProxy._isPathContained aComps, reqComps
        matchedComps = aComps
        matchedHost = port: nodule.port, host: nodule.host
    return matchedHost
  
  @_isPathContained: (root, sub) ->
    return false if sub.length < root.length
    for comp, i in root
      return true if comp == '' and i == root.length - 1
      return false if comp isnt sub[i]
    return true

module.exports = ControllableProxy
