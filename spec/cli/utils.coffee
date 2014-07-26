_ = require 'underscore'

describe 'cli utils', ->
  Given -> @subject = requireSubject 'cli/utils'

  describe 'writeLine', ->
    Given -> spyOn console, 'log'
    When -> @subject.writeLine 'foo'
    Then -> expect(console.log).toHaveBeenCalledWith '  ', 'foo'

  describe 'writeLines', ->
    Given -> spyOn console, 'log'
    When -> @subject.writeLines 'foo', 'bar'
    Then -> expect(_(console.log.calls).pluck('args')).toEqual [
      [], ['  ', 'foo'], ['  ', 'bar'], []
    ]
