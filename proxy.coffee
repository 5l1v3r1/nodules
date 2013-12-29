exports.setFlag = (req, res) ->
  flag = req.query.flag
  if typeof flag != 'string'
    res.sendJSON 400, error: 'missing/invalid flag argument'
  if not flag in ['ws', 'https', 'http_port', 'https_port']
    res.sendJSON 400, error: 'unknown flag argument'
  switch flag
    when 'ws' then

exports.start = (req, res) ->
  res.sendJSON 505, error: 'nyi'

exports.stop = (req, res) ->
  res.sendJSON 505, error: 'nyi'
