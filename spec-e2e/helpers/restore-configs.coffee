fs = require 'fs'
cp = require 'child_process'
sha = null
cp.spawn('git', ['rev-parse', '--short', 'HEAD']).on 'data', (data) ->
  sha = data.toString()

afterEach (done) -> cp.spawn('git', ['reset', sha]).on 'close', done
afterEach (done) -> cp.spawn('git', ['checkout', 'spec-e2e/cli/ftoggle.*.json']).on 'close', done
