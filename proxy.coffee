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

  start: (req, res) ->
    res.sendJSON 505, error: 'nyi'

  stop: (req, res) ->
    res.sendJSON 505, error: 'nyi'

  status: (req, res) ->
    res.sendJSON 200, running: false

module.exports = ProxySession
