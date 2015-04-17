{spawn, exec} = require 'child_process'
fs            = require 'fs'
path          = require 'path'

option '-w', '--watch', 'continually build the library'

task 'build', 'build the library', (options) ->
  coffee = spawn 'coffee', ['-c' + (if options.watch then 'w' else ''), '-o', 'lib', 'src']
  coffee.stdout.on 'data', (data) -> console.log data.toString().trim()
  coffee.stderr.on 'data', (data) -> console.log data.toString().trim()
