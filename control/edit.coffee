{NoduleArgs} = require('./lib/args.coffee')
http = require 'http'

printOptions = ->
  console.log 'Usage: ... edit <password> <port> <NODULE ARGS>'
  console.log ' NODULE ARGS: ' + NoduleArgs.usage() + '\n'
  console.log 'Example: nodule edit password 8000 /path/to/it myident 1337 --PATH=/foo --NODE_PATH=/foo/node_modules --url http://example.com --url http://mysite.com --autorelaunch --args node main.js 1337\n'
  process.exit(1)

module.exports = (argv) ->  
  printOptions() if argv.length < 4

  try
    args = new NoduleArgs(argv[4..])
  catch e
    console.log 'error: ' + e
    printOptions()

  password = argv[2]
  port = parseInt argv[3]
  encoded = new Buffer JSON.stringify args
  request = 
    hostname: 'localhost'
    port: port
    path: '/nodule/edit?password=' + encodeURIComponent password
    method: 'POST'
    headers:
      'Content-Type': 'application/json'
      'Content-Length': encoded.length

  req = http.request request, (res) -> res.pipe process.stdout
  req.on 'error', (err) ->
    console.log err.toString()

  req.write encoded
  req.end
