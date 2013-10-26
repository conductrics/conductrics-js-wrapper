fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

build = (callback) ->
  coffee = spawn 'coffee', ['-j', 'conductrics-js-wrapper.js', '-c', '-o', 'lib', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0
  min = spawn 'uglifyjs', ['-nc', '-o', 'lib/conductrics-js-wrapper-min.js', 'lib/conductrics-js-wrapper.js']

task 'sbuild', 'Build lib/ from src/', ->
  build()
