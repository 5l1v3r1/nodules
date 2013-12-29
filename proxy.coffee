###
Handles the management and execution of the HTTP/HTTPS proxy.
###

class ProxySession
  constructor: (@nodule) ->
  
  setFlag: (req, res) ->
    flag = req.query.flag
    if typeof flag != 'string'
      res.sendJSON 400, error: 'missing/invalid flag argument'
    if not flag in ['ws', 'https', 'http_port', 'https_port']
      res.sendJSON 400, error: 'unknown flag argument'
    switch flag
      when 'ws' then

  startup: (cb) ->
    # TODO: do initial startup here
    cb?()

  start: (req, res) ->
    @startup (err) ->
      if err then res.sendJSON 500, error: err.toString()
      else res.sendJSON 200, {}
    

  stop: (req, res) ->
    res.sendJSON 505, error: 'nyi'

  status: (req, res) ->
    res.sendJSON 200, running: false

module.exports = ProxySession
