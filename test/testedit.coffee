http = require 'http'

if process.argv.length isnt 5
  console.log 'Usage: coffeee testedit.coffee <password> <port> <autolaunch>'
  process.exit 1

if not process.argv[4] in ['true', 'false']
  console.log '<autolaunch> must be true or false'
  process.exit 1

password = process.argv[2]
document =
  path: __dirname + '/touch_nodule'
  identifier: 'testcase'
  port: 5000
  arguments: [process.execPath, 'executable.js']
  env: {}
  urls: []
  autolaunch: process.argv[4] is 'true'
  relaunch: true

encoded = JSON.stringify document

request = 
  hostname: 'localhost'
  port: parseInt(process.argv[3])
  path: '/nodule/edit?password=' + password
  method: 'POST'
  headers:
    'Content-Type': 'application/json'
    'Content-Length': encoded.length

req = http.request request, (res) -> res.pipe process.stdout

req.write encoded
req.end
