control_cmd = require './lib/proxy-control.coffee'
module.exports = control_cmd.bind null, 'proxy-start', 'start'
