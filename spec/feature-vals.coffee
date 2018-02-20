describe 'Builds Feature Vals', ->
  Given -> @subject = require '../lib/settings-builder'

  describe 'you got what I need', ->
    Given -> @toggles =
      e: 1
      v: 2
    Given -> @featureConfig =
      settings:
        one: 1
        two: 2
    When -> @settings = @subject.build(@toggles, @featureConfig)
    Then -> expect(@settings).toEqual(@featureConfig.settings)

  describe 'not too bad', ->
    Given -> @featureConfig = {}
    When -> @settings = @subject.build(@toggles, @featureConfig)
    Then -> expect(@settings).toEqual({})

  describe 'really? Nothing?', ->
    Given -> @featureConfig = null
    When -> @settings = @subject.build(@toggles, @featureConfig)
    Then -> expect(@settings).toEqual({})



