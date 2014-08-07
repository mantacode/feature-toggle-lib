cp = require 'child_process'
path = require 'path'
fs = require 'fs'

describe 'init', ->
  context 'separate env list', ->
    afterEach (done) -> fs.unlink "#{__dirname}/node_modules/ftoggle/.ftoggle.config.json", done
    afterEach (done) -> fs.unlink "#{__dirname}/ftoggle.foo.json", done
    afterEach (done) -> fs.unlink "#{__dirname}/ftoggle.bar.json", done
    When (done) -> runCmd('ftoggle init banana -e foo -e bar -c ./', __dirname, done)
    And -> @ftConfig = require "#{__dirname}/node_modules/ftoggle/.ftoggle.config"
    And -> @foo = require "#{__dirname}/ftoggle.foo"
    And -> @bar = require "#{__dirname}/ftoggle.bar"
    Then -> expect(@ftConfig).toEqual
      environments: ['foo', 'bar']
      configDir: './'
      name: 'banana'
    And -> expect(@foo).toEqual
      version: 1
      name: 'banana-foo'
      features: {}
    And -> expect(@bar).toEqual
      version: 1
      name: 'banana-bar'
      features: {}

  context 'comma separated env list', ->
    afterEach (done) -> fs.unlink "#{__dirname}/node_modules/ftoggle/.ftoggle.config.json", done
    afterEach (done) -> fs.unlink "#{__dirname}/ftoggle.foo.json", done
    afterEach (done) -> fs.unlink "#{__dirname}/ftoggle.bar.json", done
    Given -> delete require.cache["#{__dirname}/node_modules/ftoggle/.ftoggle.config.json"]
    Given -> delete require.cache["#{__dirname}/ftoggle.foo.json"]
    Given -> delete require.cache["#{__dirname}/ftoggle.bar.json"]
    When (done) -> runCmd('ftoggle init -n banana -e foo,bar -c ./', __dirname, done)
    And -> @ftConfig = require "#{__dirname}/node_modules/ftoggle/.ftoggle.config"
    And -> @foo = require "#{__dirname}/ftoggle.foo"
    And -> @bar = require "#{__dirname}/ftoggle.bar"
    Then -> expect(@ftConfig).toEqual
      environments: ['foo', 'bar']
      configDir: './'
      name: 'banana'
    And -> expect(@foo).toEqual
      version: 1
      name: 'banana-foo'
      features: {}
    And -> expect(@bar).toEqual
      version: 1
      name: 'banana-bar'
      features: {}

  context 'using defaults', ->
    afterEach (done) -> fs.unlink "#{__dirname}/node_modules/ftoggle/.ftoggle.config.json", done
    afterEach (done) -> fs.unlink "#{__dirname}/config/ftoggle.production.json", done
    afterEach (done) -> fs.unlink "#{__dirname}/config/ftoggle.development.json", done
    Given -> delete require.cache["#{__dirname}/node_modules/ftoggle/.ftoggle.config.json"]
    When (done) -> runCmd('ftoggle init', __dirname, done)
    And -> @ftConfig = require "#{__dirname}/node_modules/ftoggle/.ftoggle.config"
    And -> @production = require "#{__dirname}/config/ftoggle.production"
    And -> @development = require "#{__dirname}/config/ftoggle.development"
    Then -> expect(@ftConfig).toEqual
      environments: ['production', 'development']
      configDir: './config'
      name: 'init'
    And -> expect(@production).toEqual
      version: 1
      name: 'init-production'
      features: {}
    And -> expect(@development).toEqual
      version: 1
      name: 'init-development'
      features: {}
