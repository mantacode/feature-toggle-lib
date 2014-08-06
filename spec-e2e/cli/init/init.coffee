cp = require 'child_process'
path = require 'path'
fs = require 'fs'

describe 'init', ->
  afterEach -> fs.unlinkSync "#{__dirname}/node_modules/ftoggle/.ftoggle.config.json"
  afterEach -> fs.unlinkSync "#{__dirname}/ftoggle.foo.json"
  afterEach -> fs.unlinkSync "#{__dirname}/ftoggle.bar.json"
  When (done) -> runCmd('ftoggle init banana -e foo -e bar -c ./', __dirname, done)
  And -> @ftConfig = require "#{__dirname}/node_modules/ftoggle/.ftoggle.config"
  And -> @foo = require "#{__dirname}/ftoggle.foo"
  And -> @bar = require "#{__dirname}/ftoggle.bar"
  Then -> expect(@ftConfig).toEqual
    environments: ['foo', 'bar']
    configDir: path.resolve(__dirname) + '/'
    name: 'banana'
    foo:
      path: '../../ftoggle.foo.json'
    bar:
      path: '../../ftoggle.bar.json'
  And -> expect(@foo).toEqual
    version: 1
    name: 'banana-foo'
    features: {}
  And -> expect(@bar).toEqual
    version: 1
    name: 'banana-bar'
    features: {}
