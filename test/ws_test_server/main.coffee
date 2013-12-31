express = require 'express'
http = require 'http'
https = require 'https'
url = require 'url'
path = require 'path'

if process.argv.length != 3
  console.log 'Usage: coffee main.coffee <port>'
  process.exit 1
  
app = express()
server = http.createServer app

# remove the first path component
###
app.use (req, res, next) ->
  parsed = url.parse req.url
  comps = parsed.pathname.split '/'
  comps = comps[2..] if comps[1] == 'ws_test'
  parsed.pathname = '/' + comps.join '/'
  req.url = url.format parsed
  next()
###

io = require('socket.io').listen server
io.set 'resource', '/ws_test/socket.io'
io.sockets.on 'connection', (socket) ->
  index = 0
  socket.emit 'message', {index: 0}
  socket.on 'echo', ->
    socket.emit 'message', {index: ++index}
  socket.on 'close', ->
    console.log 'socket closed'

app.use '/ws_test', express.static __dirname + '/assets'
app.get '/ws_test/getheaders', (req, res) ->
  res.writeHead 200, 'Content-Type': 'application/json'
  res.end JSON.stringify req.headers
  
server.listen parseInt process.argv[2]
