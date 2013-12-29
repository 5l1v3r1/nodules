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
  
  constructor: (@path, @identifier, @port, @arguments,
                @env, @urls, @autolaunch, @relaunch) ->
  
  @load: (dict) ->
    if typeof dict isnt 'object'
      throw new Error 'invalid nodule object'
    if typeof dict.path isnt 'string'
      throw new Error 'invalid path'
    if typeof dict.identifier isnt 'string'
      throw new Error 'invaild identifier'
    if typeof dict.port isnt 'number'
      throw new Error 'invalid port'
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
    return new NoduleData(dict.path,
                          dict.identifier,
                          dict.port, 
                          dict.arguments, 
                          dict.env, 
                          dict.urls, 
                          dict.autolaunch, 
                          dict.relaunch)

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
    if typeof dict.ssl isnt 'object'
      throw new Error 'invalid ssl certificates attribute'
    if typeof dict.ports isnt 'object'
      throw new Error 'invalid ports attribute'
    if typeof dict.ports.http isnt 'number'
      throw new Error 'invalid http port'
    if typeof dict.ports.https isnt 'number'
      throw new Error 'invalid https port'
    {@ws, @https, @ssl, @ports} = dict

class Configuration
  constructor: (@nodules, @proxy, @path) ->
  
  save: (cb) ->
    encoded = JSON.stringify this
    fs.writeFile @path encoded (err) ->
      cb err
  
  toJSON: () -> nodules: @nodules, proxy: @proxy
  
  @load: (path, cb) ->
    fs.readFile path, (err, data) ->
      return cb err if err
      try
        config = JSON.parse data.toString();
        if typeof config != 'object'
          return cb new Error 'invalid root datatype'
        if not config.nodules instanceof Array
          return cb new Error 'invalid nodules datatype'
        
        nodules = NoduleData.mapload config.nodules
        proxy = new ProxyConfig config.proxy
        cb null, new Configuration nodules, proxy, path
      catch exc
        cb(exc)

exports.Configuration = Configuration;
exports.NoduleData = NoduleData;
exports.ProxyConfig = ProxyConfig;
