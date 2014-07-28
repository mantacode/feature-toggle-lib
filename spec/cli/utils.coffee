_ = require 'underscore'

describe 'cli utils', ->
  Given -> @resolve = jasmine.createSpyObj 'resolve', ['sync']
  Given -> @path = jasmine.createSpyObj 'path', ['resolve']
  Given -> @subject = requireSubject 'cli/utils',
    resolve: @resolve
    path: @path

  describe '.writeBlock', ->
    Given -> spyOn console, 'log'
    When -> @subject.writeBlock 'foo', 'bar'
    Then -> expect(_(console.log.calls).pluck('args')).toEqual [
      [], ['  ', 'foo'], ['  ', 'bar'], []
    ]

  describe '.getRoot', ->
    Given -> @resolve.sync.when('feature-toggle-lib/package.json', { basedir: process.cwd() }).thenReturn 'resolved'
    Given -> @path.resolve.when('resolved', '/../../').thenReturn 'absolute path'
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

