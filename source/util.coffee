fs = require 'fs'

# loads files asynchronously in an object
# eg {"cert": "myfile.cer", "files": ["abcd.txt", "defg.txt"]}
exports.loadFileFields = (obj, cb) ->
  if typeof obj == 'string'
    return fs.readFile obj, (err, data) ->
      cb err, data
  throw new Error 'unsupported type' if typeof obj != 'object'
  
  # recursively load files in Array
  if obj instanceof Array
    return cb null, [] if obj.length == 0
    remaining = obj[1..]
    return fs.readFile obj[0], (err, data) ->
      return cb err if err?
      exports.loadFileFields remaining, (err, rem) ->
        return cb err if err?
        return cb null, [data].concat rem

  # recursively load files in object
  keys = (key for own key of obj)
  return cb null, {} if keys.length == 0
  
  loadKey = keys[0]
  remainingObject = {}
  for own key, value of obj
    remainingObject[key] = value if key isnt loadKey
  exports.loadFileFields remainingObject, (err, rem) ->
    return cb err, null if err?
    exports.loadFileFields obj[loadKey], (err, data) ->
      return cb err, null if err?
      rem[loadKey] = data
      cb null, rem
