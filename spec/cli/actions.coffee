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
      context 'enable is true', ->
        Given -> @options =
          env: ['env']
          enable: true
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 1 }, undefined
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@options.commitMsg).toBe 'Added ftoggle feature foo.bar to env'
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar'

      context 'enable is false', ->
        Given -> @options =
          env: ['env']
          enable: false
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 0 }, undefined
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@options.commitMsg).toBe 'Added ftoggle feature foo.bar to env'
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar'

      context 'enable includes env', ->
        Given -> @options =
          env: ['env']
          enable: ['env']
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 1 }, undefined
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@options.commitMsg).toBe 'Added ftoggle feature foo.bar to env'
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar'

      context 'enable does not includes env', ->
        Given -> @options =
          env: ['env']
          enable: ['visagoths']
          splitPlan: 'vikings'
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 0 }, 'vikings'
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@options.commitMsg).toBe 'Added ftoggle feature foo.bar to env'
        And -> expect(@cb).toHaveBeenCalledWith null, 'foo.bar'

      context 'enable is undefined', ->
        Given -> @options =
          env: ['env']
          modified: []
          ftoggle:
            env:
              config:
                features: {}
        When -> @subject.add.apply @options, ['foo.bar', @cb]
        Then -> expect(@utils.expand).toHaveBeenCalledWith {}, 'foo.bar', { traffic: 0 }, undefined
        And -> expect(@options.modified).toEqual ['env']
        And -> expect(@options.commitMsg).toBe 'Added ftoggle feature foo.bar to env'
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
