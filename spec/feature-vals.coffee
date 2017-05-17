describe "Builds Feature Vals", ->
  Given -> @subject = require '../lib/feature-vals'

  describe "you got what I need", ->
    Given -> @userConfig =
      e: 1
      v: 2
    Given -> @toggleConfig =
      conf:
        one: 1
        two: 2
    When -> @conf = @subject.build(@userConfig, @toggleConfig)
    Then -> expect(@conf).toEqual(@toggleConfig.conf)

  describe "not too bad", ->
    Given -> @toggleConfig = {}
    When -> @conf = @subject.build(@userConfig, @toggleConfig)
    Then -> expect(@conf).toEqual({})

  describe "really? Nothing?", ->
    Given -> @toggleConfig = null
    When -> @conf = @subject.build(@userConfig, @toggleConfig)
    Then -> expect(@conf).toEqual({})



