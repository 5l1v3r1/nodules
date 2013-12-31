#!/usr/bin/env coffee

commands = ['passwd', 'add', 'edit', 'list', 'start', 'stop', 'delete',
            'proxy-flag', 'proxy-status', 'proxy-stop', 'proxy-start',
            'proxy-setcert']

if process.argv.length < 3
  console.log 'Usage: ./nodule <command>'
  console.log '\ncommands:\n'
  for cmd in commands
    console.log '  ' + cmd
  console.log ''
  process.exit 1

if not process.argv[2] in commands
  console.log 'unknown command: ' + process.argv[2]
  process.exit 1

module = require './control/' + process.argv[2]
module(process.argv[1..])