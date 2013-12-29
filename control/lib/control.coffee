http = require 'http'

module.exports = (name, cmd) ->
  printOptions = ->
    console.log 'Usage: coffee ' + name + ' <password> <port> <identifier>'
    process.exit(1)

  printOptions() if process.argv.length < 5

  password = process.argv[2]
  port = parseInt(process.argv[3])
  identifier = process.argv[4]

  url = "http://localhost:#{port}/nodule/#{cmd}?password=#{encodeURIComponent password}&identifier=#{encodeURIComponent identifier}"
  req = http.get url, (res) -> res.pipe process.stdout
  req.on 'error', (err) ->
    console.log err.toString()
