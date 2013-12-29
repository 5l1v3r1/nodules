http = require 'http'

if process.argv.length isnt 4
  console.log 'Usage: coffeee list.coffee <password> <port>'
  process.exit 1

password = process.argv[2]
port = parseInt(process.argv[3])


url = "http://localhost:#{port}/nodule/list?password=#{encodeURIComponent password}"
buffer = new Buffer('')
req = http.get url, (res) -> 
  res.on 'data', (e) ->
    buffer = Buffer.concat([buffer, e])
  res.on 'end', ->
    data = JSON.parse(buffer.toString())
    console.log JSON.stringify data, null, 2
