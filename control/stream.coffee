io = require 'socket.io-client'

module.exports = (argv) ->
  if argv.length isnt 5
    console.log 'Usage: ... stream <password> <port> <identifier>'
    process.exit 1

  password = argv[2]
  port = parseInt argv[3]
  identifier = argv[4]
  
  encPass = encodeURIComponent password
  socket = io.connect 'http://localhost:' + port + '/?password=' + encPass
  socket.on 'error', (err) ->
    console.log err
    console.log err.stack()
    process.exit 1
  socket.on 'disconnect', -> process.exit 0
  socket.on 'connect', ->
    socket.on 'none', ->
      console.log 'identifier not registered.'
      process.exit 1
    socket.on 'stdout', (d) -> 
      process.stdout.write new Buffer d.data
    socket.on 'stderr', (d) -> 
      process.stderr.write new Buffer d.data
    socket.on 'exit', -> process.exit 0
    socket.emit 'nodule', {identifier: identifier}
