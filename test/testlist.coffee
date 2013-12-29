http = require 'http'

if process.argv.length isnt 4
  console.log 'Usage: coffeee testlist.coffee <password> <port>'
  process.exit 1

password = process.argv[2]
port = parseInt(process.argv[3])


url = "http://localhost:#{port}/nodule/list?password=#{encodeURIComponent password}"
req = http.get url, (res) -> res.pipe process.stdout
