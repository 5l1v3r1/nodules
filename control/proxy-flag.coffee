http = require 'http'

printOptions = ->
  console.log 'Usage: ... proxy-flag <password> <port> <flag> <value>'
  console.log '\nflags:\n'
  console.log ' ws         (true/false) enable websockets'
  console.log ' http       (true/false) enable http'
  console.log ' https      (true/false) enable https'
  console.log ' http_port  (numeric) HTTP port'
  console.log ' https_port (numeric) HTTPS port'
  console.log ''
  process.exit 1

module.exports = (argv) ->  
  printOptions() if argv.length < 6

  password = argv[2]
  port = parseInt argv[3]
  query = "/proxy/setflag?flag=#{argv[4]}&setting=#{argv[5]}"
  query += '&password=' + encodeURIComponent password
  http.get "http://localhost:#{port}#{query}", (d) ->
    d.pipe process.stdout
