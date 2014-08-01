_ = require 'underscore'

describe 'cli utils', ->
  Given -> @resolve = jasmine.createSpyObj 'resolve', ['sync']
  Given -> @path = jasmine.createSpyObj 'path', ['resolve', 'dirname']
  Given -> @subject = requireSubject 'cli/utils',
    resolve: @resolve
    path: @path
    'foo file': 'foo exports'
    'bar file': 'bar exports'
    underscore: _

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
