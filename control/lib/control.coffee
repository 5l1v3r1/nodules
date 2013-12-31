http = require 'http'

module.exports = (name, cmd, argv) ->
  printOptions = ->
    console.log 'Usage: ... ' + name + ' <password> <port> <identifier>'
    process.exit(1)

  printOptions() if argv.length < 5

  password = argv[2]
  port = parseInt(argv[3])
  identifier = argv[4]

  url = "http://localhost:#{port}/nodule/#{cmd}?password=#{encodeURIComponent password}&identifier=#{encodeURIComponent identifier}"
  req = http.get url, (res) -> res.pipe process.stdout
  req.on 'error', (err) ->
    console.log err.toString()
