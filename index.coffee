module.exports =
  datastore: require './source/datastore.coffee'
  Session: require './source/nodule.coffee'
  ControllableProxy: require './source/proxy.coffee'
  LogStream: require './source/logstream.coffee'
  commands: {}

commands = ['passwd', 'add', 'edit', 'list', 'start', 'stop', 'delete',
            'proxy-flag', 'proxy-status', 'proxy-stop', 'proxy-start',
            'proxy-setcert', 'restart', 'stream']

for cmd in commands
  module.exports.commands[cmd] = require './control/' + cmd
