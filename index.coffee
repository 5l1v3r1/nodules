module.exports =
  datastore: require './source/datastore.coffee'
  Session: require './source/nodule.coffee'
  ControllableProxy: require './source/proxy.coffee'
  commands: {}

commands = ['passwd', 'add', 'edit', 'list', 'start', 'stop', 'delete',
            'proxy-flag', 'proxy-status', 'proxy-stop', 'proxy-start',
            'proxy-setcert', 'restart']

for cmd in commands
  module.exports.commands[cmd] = require './control/' + cmd
