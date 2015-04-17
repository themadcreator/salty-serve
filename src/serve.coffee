


serve = (port = 2718, keyfile) ->
  http     = require('http')
  url      = require('url')
  path     = require('path')
  nacl     = require('js-nacl').instantiate()
  fs       = require('fs')
  Promise  = require('bluebird')
  readDir  = Promise.promisify(fs.readdir)
  readFile = Promise.promisify(fs.readFile)
  gzip     = Promise.promisify(require('zlib').gzip)

  encode = (message) ->
    nonce  = nacl.crypto_box_random_nonce()
    packet = nacl.crypto_box(
      message
      nonce
      nacl.from_hex(keyfile.clientPublicKey)
      nacl.from_hex(keyfile.serverPrivateKey)
    )
    return {
      nonce  : nacl.to_hex(nonce)
      packet : nacl.to_hex(packet)
    }

  serveFile = (res, filename) ->
    return readFile(filename)
      .then (contents) ->
        encoded     = encode(contents)
        stringified = JSON.stringify(encoded)
        return gzip(new Buffer(stringified))
      .then (compressed) ->
        res.writeHead(200, {
          'Content-Type'        : 'application/json'
          'Content-Disposition' : 'Attachment'
          'Content-Encoding'    : 'gzip'
        })
        res.write(compressed)
        res.end()

  listFiles = (res, directory) ->
    return readDir(directory).then (files) ->
      files = files.filter((filename) -> fs.statSync(filename).isFile())
      res.writeHead(200, {'Content-Type' : 'text/plain'})
      res.write(files.join('\n') + '\n')
      res.end()

  server = http.createServer (req, res) ->
    uri      = url.parse(req.url).pathname
    filename = path.join(process.cwd(), uri)
    return new Promise((resolve) -> fs.exists(filename, resolve))
      .then (exists) ->
        if not exists
          console.error("404: Requested #{filename}")
          res.writeHead(404, {'Content-Type' : 'text/plain'})
          res.end()
          return
        if fs.statSync(filename).isDirectory()
          return listFiles(res, filename)
        else
          return serveFile(res, filename)
      .catch (err) ->
        console.error err?.stack ? err
        res.writeHead(500, {'Content-Type' : 'text/plain'})
        res.end()

  return new Promise((resolve) -> server.listen(port, resolve))

run = ->

  commander = require('commander')
  commander
    .version(require('../package.json').version)
    .description('Securely serve files from the current directory over HTTP.')
    .usage('-p [port] -k [server-keys.json]')
    .option('-p, --port [port]', 'HTTP server port')
    .option('-k, --keys [keyfile]', 'Server keyfile. Generate with salty-keygen.')
    .parse(process.argv)

  unless commander.port? then commander.help()
  unless commander.keys? then commander.help()

  unless require('fs').existsSync(commander.keys)
    console.error "Could not find keys file #{commander.keys}"
    process.exit(1)

  require('./read-stream')(require('fs').createReadStream(commander.keys))
  .then(JSON.parse)
  .then((keyfile) -> serve(commander.port, keyfile))
  .then(-> console.log "Running salty server on #{commander.port}")
  .catch((err) ->
    console.error err?.stack ? err
    process.exit(1)
  )

if require.main is module then do(run) else return module.exports = {run}
