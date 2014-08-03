_ = require 'underscore'
EventEmitter = require('events').EventEmitter

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
    And -> expect(@cb).toHaveBeenCalledWith undefined, 'feature', 'traffic'

  describe '.write', ->
    Given -> spyOn(@subject, 'getRoot').andReturn 'blah'
    Given -> @options =
      environments: ['banana', 'pear']
      ftoggle:
        banana:
          path: '../../banana'
          config:
            version: 1
        pear:
          path: '../../pear'
          config:
            version: 1
    Given -> @cb = jasmine.createSpy 'cb'
    Given -> @fs.writeFile.andCallFake (path, obj, cb) -> cb()
    When -> @subject.write.apply @options, ['traffic', 'feature', @cb]
    Then -> expect(@fs.writeFile).toHaveBeenCalledWith 'blah/banana', JSON.stringify(version: 1), jasmine.any(Function)
    And -> expect(@fs.writeFile).toHaveBeenCalledWith 'blah/pear', JSON.stringify(version: 1), jasmine.any(Function)
    And -> expect(@cb).toHaveBeenCalledWith undefined, 'traffic', 'feature'

  describe '.add', ->
    Given -> spyOn(@subject, 'getRoot').andReturn 'blah'
    Given -> @add = new EventEmitter()
    Given -> @cp.spawn.when('git', ['add', 'blah/config/*']).thenReturn @add
    When -> @subject.add
