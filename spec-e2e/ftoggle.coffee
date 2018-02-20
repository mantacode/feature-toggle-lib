_ = require('lodash')
Ftl = require('../lib/feature-toggle')
featureConfig = require('./fixtures/ftoggle')
config = require('./fixtures/config')
final = require('./fixtures/final')

describe 'ftoggle', ->
  Given -> @subject =  new Ftl()
  Given -> @subject.setConfig(featureConfig).addConfig(config)
  Given -> @ftoggle = @subject.create()

  context 'sets config', ->
    Then -> expect(@ftoggle.featureConfig).toEqual final
    And -> expect(@ftoggle.serialize()).toBeOneOf '2zLaEz3', '2zLaFz3'

  context 'sets toggles based on traffic', ->
    Then -> expect(@ftoggle.toggles.e).toBe 1
    And -> expect(@ftoggle.toggles.v).toBe 2
    And -> expect(@ftoggle.toggles.foo).toEqual e: 1
    And -> expect(@ftoggle.toggles.treatments.e).toBe 1
    And -> expect(@ftoggle.toggles.treatments.treatment_a.e + @ftoggle.toggles.treatments.treatment_b.e).toBe 1

  context 'sets features', ->
    When -> @features = @ftoggle.getSettings()
    Then -> expect(@features.topEnabled).toBe true
    And -> expect(@features.fooEnabled).toBe true
    And -> expect(@features).toHaveOneEnabled 'treatmentAEnabled', 'treatmentBEnabled'
    And ->
      if @features.treatmentAEnabled
        expect(@features.topOfSplitEnabled).toBe true
      else
        expect(@features.topOfSplitEnabled).toBe false

  context 'isFeatureEnabled', ->
    context 'returns true for enabled features', ->
      Then -> expect(@ftoggle.isFeatureEnabled('foo')).toBe true

    context 'returns true for enabled features', ->
      Then -> expect(@ftoggle.isFeatureEnabled('bar')).toBe false

  context 'findEnabledChildren', ->
    context 'top level', ->
      Then -> expect(@ftoggle.findEnabledChildren()).toEqual ['foo', 'treatments']

    context 'lower level', ->
      Then -> expect(@ftoggle.findEnabledChildren('treatments')).toContainOneOf 'treatment_a', 'treatment_b'

  context 'doesFeatureExist', ->
    context 'existing and enabled feature', ->
      Then -> expect(@ftoggle.doesFeatureExist('foo')).toBe true

    context 'existing and disabled feature', ->
      Then -> expect(@ftoggle.doesFeatureExist('bar')).toBe true

    context 'nested feaure', ->
      Then -> expect(@ftoggle.doesFeatureExist('treatments.treatment_a')).toBe true

    context 'non-existent feature', ->
      Then -> expect(@ftoggle.doesFeatureExist('chicken')).toBe false

  context 'getSetting', ->
    context 'feature is set', ->
      Then -> expect(@ftoggle.getSetting('fooEnabled')).toBe true

    context 'feature is unset', ->
      Then -> expect(@ftoggle.getSetting('barEnabled')).toBe null

  context 'uses current packed config', ->
    Given -> @ftoggle = @subject.create('2zLaEz3')
    Then -> expect(@ftoggle.toggles).toEqual
      v: 2
      e: 1
      foo:
        e: 1
      bar:
        e: 0
      treatments:
        e: 1
        treatment_b:
          e: 1
        treatment_a:
          e: 0
      fruits:
        e: 0
        apple:
          e: 0
          red_apple:
            e: 0
          green_apple:
            e: 0
        banana:
          e: 0
          green_banana:
            e: 0
          yellow_banana:
            e: 0

  context 'does not use old packed config', ->
    Given -> @ftoggle = @subject.create('1zLaEz3')
    Then -> expect(@ftoggle.serialize()).not.toEqual '1zLaEz3'

  context 'programmatically enable a feature', ->
    Given -> @ftoggle = @subject.create('2zLaEz3')
    Given -> @ftoggle.enable('fruits')
    Then -> expect(@ftoggle.serialize()).toBe '2zLAEz3'

  context 'programmatically disable a feature', ->
    Given -> @ftoggle = @subject.create('2zLAEz3')
    Given -> @ftoggle.disable('fruits')
    Then -> expect(@ftoggle.serialize()).toBe '2zLaEz3'
