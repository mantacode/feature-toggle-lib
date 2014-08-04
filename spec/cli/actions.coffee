path = require 'path'

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
      configDir: 'banana/config'
      name: 'banana'
      foo:
        path: '../../config/ftoggle.foo.json'
      bar:
        path: '../../config/ftoggle.bar.json'
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
    Given -> spyOn(global, 'setImmediate').andCallFake (f) -> f()
    Given -> @cb = jasmine.createSpy 'cb'
    context 'with existing config env', ->
      Given -> @options =
        env: ['env']
        modified: []
        ftoggle:
          env:
            config:
              features: {}
      When -> @subject.add.apply @options, ['foo.bar', @cb]
      Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 1 }
      And -> expect(@options.modified).toEqual ['env']
      And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar'

    context 'with non-existent env', ->
      Given -> @options =
        env: ['banana']
        modified: []
        ftoggle:
          env:
            config:
              features: {}
      When -> @subject.add.apply @options, ['foo.bar', @cb]
      Then -> expect(@utils.expand).not.toHaveBeenCalled()
      And -> expect(@options.modified).toEqual []
      And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar'
