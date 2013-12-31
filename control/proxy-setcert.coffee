http = require 'http'

module.exports = (argv) ->
  if argv.length < 6
    console.log 'Usage: ... proxy-setcert <password> <port> <cert file> <key file> [--ca ca_file] [--host=hostname]'
    process.exit 1

  password = argv[2]
  port = parseInt argv[3]
  domain = null
  caFiles = []
  
  i = 6
  while i < argv.length
    arg = argv[i]
    if arg is '--ca'
      caFiles.push argv[++i]
    else if match = /--host=(.*)/.exec arg
      domain = match[1]
    else
      console.log 'unrecognized option: ' + arg
      process.exit 1
    i++

  command =
    entry:
      cert: argv[4]
      key: argv[5]
  command.entry.ca = caFiles if caFiles.length > 0
  command.domain = domain if domain
  encoded = new Buffer JSON.stringify command
  request = 
    hostname: 'localhost'
    port: port
    path: '/proxy/setcert?password=' + encodeURIComponent password
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Content-Length': encoded.length
      
  req = http.request request, (res) -> 
    res.pipe process.stdout
  
  req.end encoded
