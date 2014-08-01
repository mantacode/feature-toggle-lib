path = require 'path'
utils = require '../../cli/utils'

describe 'actions', ->
  Given -> @fs = jasmine.createSpyObj 'fs', ['exists', 'writeFile']
  Given -> @utils = jasmine.createSpyObj 'utils', ['getRoot', 'exit', 'iterate', 'expand']
  Given -> @subject = requireSubject 'cli/actions',
    fs: @fs
    './utils': @utils

  describe '.init', ->
    Given -> @utils.getRoot.andReturn 'banana'
    Given -> @fs.writeFile.andCallFake (path, content, cb) -> cb()
    Given -> @options =
      env: [ 'foo', 'bar' ]
      configDir: 'config'
      name: 'banana'
    When -> @subject.init undefined, @options
    Then -> expect(@fs.writeFile).toHaveBeenCalledWith 'banana/node_modules/feature-toggle-lib/.ftoggle.config.json', JSON.stringify(
      environments: ['foo', 'bar']
      foo: '../../config/ftoggle.foo.json'
      bar: '../../config/ftoggle.bar.json'
    , null, 2), jasmine.any(Function)
    And -> expect(@fs.writeFile).toHaveBeenCalledWith 'banana/config/ftoggle.foo.json', JSON.stringify(
      version: 1
      name: 'banana-foo'
      features: {}
    , null, 2), jasmine.any(Function)
    And -> expect(@fs.writeFile).toHaveBeenCalledWith 'banana/config/ftoggle.bar.json', JSON.stringify(
      version: 1
      name: 'banana-bar'
      features: {}
    , null, 2), jasmine.any(Function)
    And -> expect(@utils.exit).toHaveBeenCalled()

  describe '.add', ->
    Given -> @utils.expand.plan = utils.expand
    Given -> @add = jasmine.captor()
    Given -> @options =
      ftoggle:
        env:
          config:
            features: {}
    Given -> @next = jasmine.createSpy 'next'
    When -> @subject.add 'foo.bar', @options
    And -> expect(@utils.iterate).toHaveBeenCalledWith @options, @add.capture(), @utils.exit
    And -> @add.value 'env', @next
    Then -> expect(@options.ftoggle.env.config.features).toEqual
      foo:
        traffic: 1
        features:
          bar:
            traffic: 1
    And -> expect(@next).toHaveBeenCalled()
