describe.only "Builds Feature Vals", ->
  Given -> @subject = new (requireSubject 'lib/builds-feature-vals')

  describe "you got what I need", ->
    Given -> @toggleConfig =
      conf:
        one: 1
        two: 2
    When -> @conf = @subject.confFor(@toggleConfig)
    Then -> expect(@conf).toEqual(@toggleConfig.conf)

  describe "not too bad", ->
    Given -> @toggleConfig = {}
    When -> @conf = @subject.confFor(@toggleConfig)
    Then -> expect(@conf).toEqual({})

  describe "really? Nothing?", ->
    Given -> @toggleConfig = null
    When -> @conf = @subject.confFor(@toggleConfig)
    Then -> expect(@conf).toEqual({})



