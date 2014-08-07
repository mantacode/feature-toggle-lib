fs = require 'fs'
cp = require 'child_process'
sha = null
path = require 'path'
parse = cp.spawn('git', ['rev-parse', '--short', 'HEAD'])
parse.stdout.on 'data', (data) ->
  sha = data.toString()

afterEach (done) -> cp.spawn('git', ['reset', sha]).on 'close', -> done()
afterEach (done) -> cp.spawn('git', ['checkout', "#{path.resolve(__dirname, '../cli')}/ftoggle.*.json"]).on 'close', -> done()
