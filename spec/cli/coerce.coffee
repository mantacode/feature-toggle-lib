describe 'coerce', ->
  Given -> @subject = requireSubject 'cli/coerce'

  describe '.collect', ->
    Given -> @list = []
    When -> @subject.collect 'foo', @list
    And -> @subject.collect 'bar', @list
    And -> @subject.collect 'baz', @list
    Then -> expect(@list).toEqual [ 'foo', 'bar', 'baz' ]
