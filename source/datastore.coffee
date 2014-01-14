fs = require 'fs'

DEFAULT_PROXY =
  ws: true
  https: false
  ssl: {}
  ports:
    http: 80
    https: 443

###
An object which represents the configuration of a nodule.
###
class NoduleData
  
  constructor: (@path, @identifier, @port, @host, @arguments,
                @env, @urls, @autolaunch, @relaunch, @gid, @uid) ->
  
  @load: (dict) ->
    if typeof dict isnt 'object'
      throw new Error 'invalid nodule object'
    if typeof dict.path isnt 'string'
      throw new Error 'invalid path'
    if typeof dict.identifier isnt 'string'
      throw new Error 'invaild identifier'
    if typeof dict.port isnt 'number'
      throw new Error 'invalid port'
    if typeof dict.host isnt 'string'
      throw new Error 'invalid host'
    if not dict.arguments instanceof Array
      throw new Error 'invaild arguments'
    if typeof dict.env isnt 'object'
      throw new Error 'invalid environment'
    if not dict.urls instanceof Array
      throw new Error 'invalid urls'
    if typeof dict.autolaunch isnt 'boolean'
      throw new Error 'invalid autolaunch'
    if typeof dict.relaunch isnt 'boolean'
      throw new Error 'invalid relaunch'
    if dict.uid? and typeof dict.uid isnt 'number'
      throw new Error 'invalid UID'
    if dict.gid? and typeof dict.gid isnt 'number'
      throw new Error 'invalid GID'
    
    # verify the types within arrays
    for url in dict.urls
      if typeof url isnt 'string'
        throw new Error 'invalid URL type'
    for arg in dict.arguments
      if typeof arg isnt 'string'
        throw new Error 'invalid argument type'
    
    # verify the values in the environment
    for own value, key of dict.env
      if not typeof value is typeof key is 'string'
        throw new Error 'invalid key/value pair in environment'
    
    return new NoduleData(dict.path,
                          dict.identifier,
                          dict.port,
                          dict.host,
                          dict.arguments,
                          dict.env,
                          dict.urls,
                          dict.autolaunch,
                          dict.relaunch,
                          dict.gid ? null,
                          dict.uid ? null)

  @mapload: (list) -> @load d for d in list

###
The configuration of the proxy is stored in this object.
###
class ProxyConfig
  constructor: (dict=DEFAULT_PROXY) ->
    if typeof dict isnt 'object'
      throw new Error 'invalid root object'
    if typeof dict.ws isnt 'boolean'
      throw new Error 'invalid ws flag'
    if typeof dict.https isnt 'boolean'
      throw new Error 'invalid https flag'
    if typeof dict.http isnt 'boolean'
      throw new Error 'invalid HTTP flag'
    if typeof dict.ssl isnt 'object'
      throw new Error 'invalid ssl certificates attribute'
    if typeof dict.ports isnt 'object'
      throw new Error 'invalid ports attribute'
    if typeof dict.ports.http isnt 'number'
      throw new Error 'invalid http port'
    if typeof dict.ports.https isnt 'number'
      throw new Error 'invalid https port'
    {@ws, @https, @http, @ssl, @ports} = dict
    throw new Error 'invalid ssl object' if not @validateSSL()
  
  validateSSL: ->
    return false if typeof @ssl.default_key != 'string'
    return false if typeof @ssl.default_cert != 'string'
    if @ssl.default_ca?
      return false if not @ssl.default_ca instanceof Array
      for a in @ssl.default_ca
        return false if typeof a != 'string'
    return false if typeof @ssl.sni != 'object'
    for own key, obj of @ssl.sni
      return false if typeof obj != 'object'
      return false if typeof obj.key != 'string'
      return false if typeof obj.cert != 'string'
      if obj.ca?
        return false if not obj.ca instanceof Array
        for a in obj.ca
          return false if typeof a != 'string'
    return true

class Configuration
  constructor: (@nodules, @proxy, @password, @path) ->
  
  save: (cb) ->
    # For now, this is synchronous so that overlaps don't occur.
    # In the future, this should be done with some sort of database.
    encoded = JSON.stringify this, null, 2
    cb fs.writeFileSync @path, encoded
  
  toJSON: -> nodules: @nodules, proxy: @proxy, password: @password
  
  @load: (path, cb) ->
    fs.readFile path, (err, data) ->
      return cb err if err
      try
        config = JSON.parse data.toString();
        if typeof config isnt 'object'
          return cb new Error 'invalid root datatype'
        if not config.nodules instanceof Array
          return cb new Error 'invalid nodules datatype'
        if typeof config.password isnt 'string'
          return cb new Error 'invalid password datatype'
        nodules = NoduleData.mapload config.nodules
        proxy = new ProxyConfig config.proxy
        passwd = config.password
      catch exc
        return cb(exc)
      cb null, new Configuration nodules, proxy, passwd, path

exports.Configuration = Configuration;
exports.NoduleData = NoduleData;
exports.ProxyConfig = ProxyConfig;
