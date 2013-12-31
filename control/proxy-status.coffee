http = require 'http'

module.exports = (argv) ->
  if argv.length isnt 4
    console.log 'Usage: ... proxy-status <password> <port>'
    process.exit 1

  password = argv[2]
  port = parseInt(argv[3])

  url = "http://localhost:#{port}/proxy/status?password=#{encodeURIComponent password}"
  buffer = new Buffer('')
  req = http.get url, (res) -> 
    res.on 'data', (e) ->
      buffer = Buffer.concat([buffer, e])
    res.on 'end', ->
      data = JSON.parse(buffer.toString())
      console.log JSON.stringify data, null, 2
