cp = require 'child_process'
path = require 'path'
fs = require 'fs'

describe 'init', ->
  afterEach -> fs.unlink "#{__dirname}/node_modules/feature-toggle-lib/.ftoggle.config"
  afterEach -> fs.unlink "#{__dirname}/ftoggle.foo"
  afterEach -> fs.unlink "#{__dirname}/ftoggle.baz"
  When (done) ->
    cp.spawn('ftoggle', ['init', 'banana', '-e', 'foo', '-e', 'bar', '-c', './'],
      cwd: __dirname
      stdio: 'inherit'
    ).on('close', done)
  And -> @ftConfig = require "#{__dirname}/node_modules/feature-toggle-lib/.ftoggle.config"
  And -> @foo = require "#{__dirname}/ftoggle.foo"
  And -> @bar = require "#{__dirname}/ftoggle.baz"
  Then -> expect(@ftConfig).toEqual
    environments: ['foo', 'bar']
    foo: './../../ftoggle.foo.json'
    bar: './../../ftoggle.bar.json'
  And -> expect(@foo).toEqual
    version: 1
    name: 'banana-foo'
    features: {}
  And -> expect(@bar).toEqual
    version: 1
    name: 'banana-bar'
    features: {}
