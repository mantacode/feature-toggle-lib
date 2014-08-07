describe 'coerce', ->
  Given -> @subject = requireSubject 'cli/coerce'

  describe '.collect', ->
    context 'called multiple times', ->
      Given -> @list = []
      When -> @subject.collect 'foo', @list
      And -> @subject.collect 'bar', @list
      And -> @subject.collect 'baz', @list
      Then -> expect(@list).toEqual [ 'foo', 'bar', 'baz' ]

    context 'called with a literal list', ->
      Given -> @list = ['foo']
      When -> @subject.collect 'bar,baz', @list
      Then -> expect(@list).toEqual ['foo', 'bar', 'baz' ]

    context 'called without param', ->
      When -> @res = @subject.collect undefined, undefined
      Then -> expect(@res).toBe true

