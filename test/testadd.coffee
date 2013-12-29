http = require 'http'

if process.argv.length isnt 4
  console.log 'Usage: coffeee testadd.coffee <password> <port>'
  process.exit 1

password = process.argv[2]
document =
  path: __dirname + '/touch_nodule'
  identifier: 'testcase'
  port: 5000
  arguments: [process.execPath, 'executable.js']
  env: {}
  urls: []
  autolaunch: true
  relaunch: true

encoded = JSON.stringify document

request = 
  hostname: 'localhost'
  port: parseInt(process.argv[3])
  path: '/nodule/add?password=' + password
  method: 'POST'
  headers:
    'Content-Type': 'application/json'
    'Content-Length': encoded.length

req = http.request request, (res) -> res.pipe process.stdout

req.write encoded
req.end
