http = require 'http'

if process.argv.length isnt 4
  console.log 'Usage: coffeee testadd.coffee <password> <port>'
  process.exit 1

password = process.argv[2]
document =
  path: __dirname + '/ws_test_server'
  identifier: 'wstest'
  port: 5003
  host: 'localhost'
  arguments: ['/usr/bin/env', 'coffee', 'main.coffee', '5003']
  env: process.env
  urls: ['http://localhost:8080/ws_test',
         'ws://localhost:8080/ws_test']
  autolaunch: true
  relaunch: false

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
