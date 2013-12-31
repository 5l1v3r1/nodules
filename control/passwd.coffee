http = require 'http'
crypto = require 'crypto'

printOptions = ->
  console.log 'Usage: ... passwd <password> <port> <new password>'
  process.exit 1

module.exports = (argv) ->  
  printOptions() if argv.length < 5

  password = argv[2]
  port = parseInt argv[3]
  newPass = argv[4]
  
  b = crypto.createHash 'sha1'
  b.update newPass
  
  query = "/api/passwd?new=#{b.digest 'hex'}"
  query += '&password=' + encodeURIComponent password
  http.get "http://localhost:#{port}#{query}", (d) ->
    d.pipe process.stdout
