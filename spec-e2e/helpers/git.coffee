cp = require 'child_process'
path = require 'path'

global.ftoggleDiff = (cb) ->
  diff = cp.spawn 'git', ['diff', 'HEAD', 'HEAD~', "#{path.resolve(__dirname, '../cli')}/ftoggle.*.json"]
  ret = ''
  diff.stdout.on 'data', (data) ->
    ret += data.toString()
  diff.on 'close', ->
    cb(null, ret)
