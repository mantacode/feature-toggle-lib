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
    Then -> expect(@fs.writeFile).toHaveBeenCalledWith 'banana/node_modules/ftoggle/.ftoggle.config.json', JSON.stringify(
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
    Given -> @cb = jasmine.createSpy 'cb'
    context 'with existing config env', ->
      context 'enable is true', ->
        Given -> @options =
          enable: true
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', 'env', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 1 }, undefined
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar', 'env'

      context 'enable is false', ->
        Given -> @options =
          enable: false
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', 'env', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 0 }, undefined
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar', 'env'

      context 'enable includes env', ->
        Given -> @options =
          enable: ['env']
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', 'env', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 1 }, undefined
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar', 'env'

      context 'enable does not includes env', ->
        Given -> @options =
          enable: ['visagoths']
          splitPlan: 'vikings'
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', 'env', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 0 }, 'vikings'
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar', 'env'

      context 'enable is undefined', ->
        Given -> @options =
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', 'env', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 0 }, undefined
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar', 'env'

    context 'with non-existent env', ->
      Given -> @options =
        modified: []
        ftoggle:
          env:
            config:
              features: {}
      When -> @subject.add.apply @options, ['foo.bar', 'banana', @cb]
      Then -> expect(@utils.expand).not.toHaveBeenCalled()
      And -> expect(@options.modified).toEqual []
      And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar', 'banana'
