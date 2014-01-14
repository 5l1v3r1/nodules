class SocketConnection
  constructor: (@socket, @session) ->
    @exitCb = @_handleExit.bind this
    @dataCb = @_handleStdout.bind this
    @stderrCb = @_handleStderr.bind this
    @nodule = null
    @socket.on 'nodule', @register.bind this
    @socket.on 'disconnect', @unregister.bind this

  register: (dict) ->
    return @socket.disconnect() if typeof dict isnt 'object'
    name = dict.identifier
    return @socket.disconnect() if typeof name isnt 'string'
    foundNodule = null
    for nodule in @session.nodules
      if nodule.data.identifier is name and nodule.isRunning()
        foundNodule = nodule
        break
    return @socket.emit 'none' if not foundNodule?
    @unregister() if @nodule?
    @nodule = foundNodule
    @nodule.process.on 'exit', @exitCb
    @nodule.process.stdout.on 'data', @dataCb
    @nodule.process.stderr.on 'data', @stderrCb
  
  unregister: ->
    return if not @nodule?
    @nodule.process?.removeListener 'exit', @exitCb
    @nodule.process?.stdout?.removeListener? 'data', @dataCb
    @nodule.process?.stderr?.removeListener? 'data', @stderrCb
    @nodule = null

  _handleExit: ->
    @unregister()
    @socket.emit 'exit'
  
  _handleStdout: (d) -> @socket.emit 'stdout', {data: d}
  _handleStderr: (d) -> @socket.emit 'stderr', {data: d}


class LogStream
  constructor: (@session) ->
  
  connection: (socket) -> new SocketConnection socket, @session

module.exports = LogStream
