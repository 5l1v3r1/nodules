http = require 'http'

if process.argv.length isnt 5
  console.log 'Usage: coffeee testremove.coffee <password> <port> <identifier>'
  process.exit 1

password = process.argv[2]
port = parseInt(process.argv[3])
identifier = process.argv[4]

url = "http://localhost:#{port}/nodule/remove?password=#{encodeURIComponent password}&identifier=#{encodeURIComponent identifier}"
req = http.get url, (res) -> res.pipe process.stdout
