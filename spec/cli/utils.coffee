_ = require 'underscore'
EventEmitter = require('events').EventEmitter
chalk = require 'chalk'

describe 'cli utils', ->
  Given -> @resolve = jasmine.createSpyObj 'resolve', ['sync']
  Given -> @path = jasmine.createSpyObj 'path', ['resolve', 'dirname']
  Given -> @fs = jasmine.createSpyObj 'fs', ['writeFile']
  Given -> @cp = jasmine.createSpyObj 'child_process', ['spawn']
  Given -> @subject = requireSubject 'cli/utils',
    resolve: @resolve
    path: @path
    'foo file': 'foo exports'
    'bar file': 'bar exports'
    underscore: _
    fs: @fs
    child_process: @cp
  ,
    String: String

  describe '.writeBlock', ->
    Given -> spyOn console, 'log'
    When -> @subject.writeBlock 'foo', 'bar'
    Then -> expect(_(console.log.calls).pluck('args')).toEqual [
      [], ['  ', 'foo'], ['  ', 'bar'], []
    ]

  describe '.getRoot', ->
    Given -> @resolve.sync.when('feature-toggle-lib/package.json', { basedir: process.cwd() }).thenReturn 'resolved'
    Given -> @path.dirname.when('resolved').thenReturn 'dirnamed'
    Given -> @path.resolve.when('dirnamed', '..', '..').thenReturn 'absolute path'
    When -> @res = @subject.getRoot()
    Then -> expect(@res).toBe 'absolute path'

  describe '.exit', ->
    Given -> spyOn process, 'exit'
    Given -> spyOn @subject, 'writeBlock'

    context 'no error', ->
      When -> @subject.exit()
      Then -> expect(process.exit).toHaveBeenCalledWith(0)

    context 'error', ->
      When -> @subject.exit('err')
      Then -> expect(@subject.writeBlock).toHaveBeenCalledWith 'err'
      And -> expect(process.exit).toHaveBeenCalledWith 1

  describe '.expand', ->
    Given -> @obj = {}
    When -> @subject.expand @obj, 'foo.bar.baz', { traffic: 1 }
    Then -> expect(@obj).toEqual
      foo:
        traffic: 1
        features:
          bar:
            traffic: 1
            features:
              baz:
                traffic: 1

  describe '.bump', ->
    Given -> @options =
      environments: ['banana', 'pear']
      modified: ['apple']
      ftoggle:
        banana:
          config:
            version: 2
        pear:
          config:
            version: 3
    Given -> @cb = jasmine.createSpy 'cb'
    When -> @subject.bump.apply @options, ['feature', 'traffic', @cb]
    Then -> expect(@options.ftoggle.banana.config.version).toEqual 4
    And -> expect(@options.ftoggle.pear.config.version).toEqual 4
    And -> expect(@options.modified).toEqual ['apple', 'banana', 'pear']
    And -> expect(@cb).toHaveBeenCalledWith undefined, 'feature', 'traffic'

  describe '.write', ->
    Given -> @options =
      modified: ['banana', 'pear', 'banana']
      configDir: 'config'
      ftoggle:
        banana:
          config:
            version: 1
        pear:
          config:
            version: 1
    Given -> @cb = jasmine.createSpy 'cb'
    Given -> @fs.writeFile.andCallFake (path, obj, cb) -> cb()
    When -> @subject.write.apply @options, ['feature', 'traffic', @cb]
    Then -> expect(@fs.writeFile).toHaveBeenCalledWith 'config/ftoggle.banana.json', JSON.stringify(version: 1), jasmine.any(Function)
    And -> expect(@fs.writeFile).toHaveBeenCalledWith 'config/ftoggle.pear.json', JSON.stringify(version: 1), jasmine.any(Function)
    And -> expect(@fs.writeFile.callCount).toBe 2
    And -> expect(@cb).toHaveBeenCalledWith undefined, 'feature', 'traffic'

  describe '.stage', ->
    Given -> @add = new EventEmitter()
    Given -> @cb = jasmine.createSpy 'cb'
    Given -> @options =
      configDir: 'config'

    context 'no error - all configs', ->
      Given -> @cp.spawn.when('git', ['add', 'config/*']).thenReturn @add
      When -> @subject.stage.apply @options, ['feature', 'traffic', @cb]
      And -> @add.emit 'close', 0
      Then -> expect(@cb).toHaveBeenCalledWith null, 'feature', 'traffic'

    context 'no error - list of configs', ->
      Given -> @options.stage = ['banana', 'pear']
      Given -> @cp.spawn.when('git', ['add', 'config/ftoggle.banana.json', 'config/ftoggle.pear.json']).thenReturn @add
      When -> @subject.stage.apply @options, ['feature', 'traffic', @cb]
      And -> @add.emit 'close', 0
      Then -> expect(@cb).toHaveBeenCalledWith null, 'feature', 'traffic'

    context 'no error - list of configs', ->
      Given -> @options.stage = ['banana', 'pear']
      Given -> @cp.spawn.when('git', ['add', 'config/ftoggle.banana.json', 'config/ftoggle.pear.json']).thenReturn @add
      When -> @subject.stage.apply @options, ['feature', 'traffic', @cb]
      And -> @add.emit 'close', 1
      Then -> expect(@cb).toHaveBeenCalledWith "#{chalk.gray('git add config/ftoggle.banana.json config/ftoggle.pear.json')} returned code #{chalk.red('1')}", 'feature', 'traffic'

    context 'error', ->
      Given -> @cp.spawn.when('git', ['add', 'config/*']).thenReturn @add
      When -> @subject.stage.apply @options, ['feature', 'traffic', @cb]
      And -> @add.emit 'close', 1
      Then -> expect(@cb).toHaveBeenCalledWith "#{chalk.gray('git add config/*')} returned code #{chalk.red('1')}", 'feature', 'traffic'

  describe '.commit', ->
    Given -> @commit = new EventEmitter
    Given -> @cp.spawn.when('git', ['commit', '-m', 'Added ftoggle feature foo.bar to banana and pear']).thenReturn @commit
    Given -> @cb = jasmine.createSpy 'cb'
    Given -> @options =
      commitMsg: 'Added ftoggle feature foo.bar to banana and pear'

    context 'no error', ->
      When -> @subject.commit.apply @options, ['feature', 'traffic', @cb]
      And -> @commit.emit 'close', 0
      Then -> expect(@cb).toHaveBeenCalledWith null, 'feature', 'traffic'

    context 'error', ->
      When -> @subject.commit.apply @options, ['feature', 'traffic', @cb]
      And -> @commit.emit 'close', 1
      Then -> expect(@cb).toHaveBeenCalledWith "#{chalk.gray('git commit -m \'Added ftoggle feature foo.bar to banana and pear\'')} returned code #{chalk.red('1')}", 'feature', 'traffic'
