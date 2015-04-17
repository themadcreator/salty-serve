fs = require('fs')

decode = (stream, clientKeyfile) ->
  Promise    = require('bluebird')
  nacl       = require('js-nacl').instantiate()
  readStream = require('./read-stream')

  return Promise.all([
    readStream(stream).then(JSON.parse)
    readStream(fs.createReadStream(clientKeyfile)).then(JSON.parse)
  ]).spread (encoded, keypair) ->
    decoded = nacl.crypto_box_open(
      nacl.from_hex(encoded.packet)
      nacl.from_hex(encoded.nonce)
      nacl.from_hex(keypair.serverPublicKey)
      nacl.from_hex(keypair.clientPrivateKey)
    )
    process.stdout.write new Buffer(decoded), 'binary'

run = ->

  commander = require('commander')
  commander
    .version(require('../package.json').version)
    .description('Decrypts NaCl crypto_box JSON from stdin to stdout using client keyfile.')
    .usage('-k [client-keys.json]')
    .option('-k, --keys [keyfile]', 'Client keyfile. Generate with salty-keygen.')
    .parse(process.argv)

  unless commander.keys? then commander.help()

  unless fs.existsSync(commander.keys)
    console.error "\nERROR: Could not find keys file '#{commander.keys}'"
    commander.help()

  decode(process.stdin, commander.keys).catch((err) ->
    console.error err?.stack ? err
    process.exit(1)
  )

if require.main is module then do(run) else return module.exports = {run}
