cp = require 'child_process'
path = require 'path'

global.ftoggleDiff = (cb) ->
  diff = cp.spawn 'git', ['diff', 'HEAD', 'HEAD~', '--', "#{path.resolve(__dirname, '../cli')}/ftoggle.*.json"]
  ret = ''
  diff.stdout.on 'data', (data) ->
    #str = data.toString()
    #name = str.match(/diff --git a\//g)
    #console.log name
    ret += data.toString()
  diff.on 'close', ->
    cb null, ret.replace(/\s+/g, ' ').replace('\n', ' ')
