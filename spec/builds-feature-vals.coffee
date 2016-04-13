describe "Builds Feature Vals", ->
  Given -> @subject = requireSubject 'lib/builds-feature-vals.js'

  describe "you got what I need", ->
    Given -> @userConfig =
      e: 1
      v: 2
    Given -> @toggleConfig =
      conf:
        one: 1
        two: 2
    When -> @conf = @subject(@userConfig, @toggleConfig)
    Then -> expect(@conf).toEqual(@toggleConfig.conf)

  describe "not too bad", ->
    Given -> @toggleConfig = {}
    When -> @conf = @subject(@userConfig, @toggleConfig)
    Then -> expect(@conf).toEqual({})

  describe "really? Nothing?", ->
    Given -> @toggleConfig = null
    When -> @conf = @subject(@userConfig, @toggleConfig)
    Then -> expect(@conf).toEqual({})



