Promise = require 'bluebird'
return module.exports = (stream) ->
  chunks = []
  return new Promise (resolve, reject) ->
    stream.on 'data', (chunk) -> chunks.push chunk
    stream.on 'error', (err) -> reject(err)
    stream.on 'end', -> resolve Buffer.concat(chunks)
