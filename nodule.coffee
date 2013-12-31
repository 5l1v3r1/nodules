#!/usr/bin/env coffee

commands = ['add', 'edit', 'list', 'start', 'stop', 'delete']

if process.argv.length < 3
  console.log 'Usage: ./nodule <command>'
  process.exit 1

if not process.argv[2] in commands
  console.log 'unknown command: ' + process.argv[2]
  process.exit 1

module = require './control/' + process.argv[2]
module(process.argv[1..])