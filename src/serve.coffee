fs = require('fs')

serve = (port, keyfile, servePath) ->
  http        = require('http')
  url         = require('url')
  path        = require('path')
  nacl        = require('js-nacl').instantiate()
  Promise     = require('bluebird')
  readDir     = Promise.promisify(fs.readdir)
  readFile    = Promise.promisify(fs.readFile)
  resolvePath = Promise.promisify(fs.realpath)
  gzip        = Promise.promisify(require('zlib').gzip)

  encode = (message) ->
    nonce  = nacl.crypto_box_random_nonce()
    packet = nacl.crypto_box(
      message
      nonce
      nacl.from_hex(keyfile.clientPublicKey)
      nacl.from_hex(keyfile.serverPrivateKey)
    )
    encrypted = {
      nonce  : nacl.to_hex(nonce)
      packet : nacl.to_hex(packet)
    }
    return gzip(new Buffer(JSON.stringify(encrypted)))

  serveFile = (res, filename) ->
    return readFile(filename)
      .then(encode)
      .then((encoded) ->
        res.writeHead(200, {
          'Content-Type'        : 'application/json'
          'Content-Disposition' : 'Attachment'
          'Content-Encoding'    : 'gzip'
        })
        res.write(encoded)
        res.end()
      )

  listFiles = (res, directory) ->
    return readDir(directory)
      .then (files) ->
        files = files.filter((filename) -> fs.statSync(path.join(directory, filename)).isFile())
        return files.join('\n') + '\n'
      .then (content) ->
        res.writeHead(200, {'Content-Type' : 'text/plain'})
        res.write(content)
        res.end()

  server = http.createServer (req, res) ->
    uri = url.parse(req.url).pathname
    resolvePath(path.join(process.cwd(), servePath, uri))
      .then (filename) ->
        if not fs.existsSync(filename)
          console.error("404: #{filename}")
          res.writeHead(404, {'Content-Type' : 'text/plain'})
          res.end()
          return
        else if fs.statSync(filename).isDirectory()
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
    .usage('-p [port] -k [server-keys.json] [path to serve]')
    .option('-p, --port [port]', 'HTTP server port', parseInt)
    .option('-k, --keys [keyfile]', 'Server keyfile. Generate with salty-keygen.')
    .parse(process.argv)

  servePath = commander.args[0]

  unless commander.port? then commander.help()
  unless commander.keys? then commander.help()
  unless servePath? then commander.help()

  unless fs.existsSync(commander.keys)
    console.error "\nERROR: Could not find keys file '#{commander.keys}'"
    commander.help()

  unless fs.existsSync(servePath) and fs.statSync(servePath).isDirectory()
    console.error "\nERROR: Invalid serve path '#{servePath}'"
    commander.help()

  require('./read-stream')(fs.createReadStream(commander.keys))
  .then(JSON.parse)
  .then((keyfile) -> serve(commander.port, keyfile, servePath))
  .then(-> console.log "Running salty server on #{commander.port}")
  .catch((err) ->
    console.error err?.stack ? err
    process.exit(1)
  )

if require.main is module then do(run) else return module.exports = {run}
