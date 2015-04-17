
generate = ->
  nacl = require('js-nacl').instantiate()

  serverKeypair = nacl.crypto_box_keypair()
  clientKeypair = nacl.crypto_box_keypair()

  serverKeyFile = {
    serverPrivateKey : nacl.to_hex(serverKeypair.boxSk)
    clientPublicKey  : nacl.to_hex(clientKeypair.boxPk)
  }

  clientKeyFile = {
    serverPublicKey  : nacl.to_hex(serverKeypair.boxPk)
    clientPrivateKey : nacl.to_hex(clientKeypair.boxSk)
  }

  fs = require 'fs'
  fs.writeFileSync('server-keys.json', JSON.stringify(serverKeyFile, null, 2) + '\n')
  fs.writeFileSync('client-keys.json', JSON.stringify(clientKeyFile, null, 2) + '\n')
  return

run = ->
  commander = require('commander')
  commander
    .version(require('../package.json').version)
    .description('Generates nacl cryptobox keypairs for client and server.')
    .parse(process.argv)

  generate()

if require.main is module then do(run) else return module.exports = {run}