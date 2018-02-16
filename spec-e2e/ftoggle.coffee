_ = require('lodash')
Ftl = require('../lib/feature-toggle')
ftoggle = require('./fixtures/ftoggle')
config = require('./fixtures/config')
final = require('./fixtures/final')

describe 'ftoggle', ->
  Given -> @subject =  new Ftl()
  Given -> @subject.setConfig(ftoggle).addConfig(config)
  Given -> @ftoggle = @subject.createConfig()

  context 'sets config', ->
    Then -> expect(@ftoggle.toggleConfig).toEqual final
    And -> expect(@ftoggle.getPackedConfig()).toBeOneOf '2zLaEz3', '2zLaFz3'

  context 'sets toggles based on traffic', ->
    Then -> expect(@ftoggle.config.e).toBe 1
    And -> expect(@ftoggle.config.v).toBe 2
    And -> expect(@ftoggle.config.foo).toEqual e: 1
    And -> expect(@ftoggle.config.treatments.e).toBe 1
    And -> expect(@ftoggle.config.treatments.treatment_a.e + @ftoggle.config.treatments.treatment_b.e).toBe 1

  context 'sets features', ->
    When -> @features = @ftoggle.getFeatureVals()
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

  context 'featureVal', ->
    context 'feature is set', ->
      Then -> expect(@ftoggle.featureVal('fooEnabled')).toBe true

    context 'feature is unset', ->
      Then -> expect(@ftoggle.featureVal('barEnabled')).toBe null

  context 'uses current cookie', ->
    Given -> @ftoggle = @subject.createConfig('2zLaEz3')
    Then -> expect(@ftoggle.config).toEqual
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

  context 'does not use old cookie', ->
    Given -> @ftoggle = @subject.createConfig('1zLaEz3')
    Then -> expect(@ftoggle.getPackedConfig()).not.toEqual '1zLaEz3'

  context 'programmatically enable a feature', ->
    Given -> @ftoggle = @subject.createConfig('2zLaEz3')
    Given -> @ftoggle.enable('fruits')
    Then -> expect(@ftoggle.getPackedConfig()).toBe '2zLAEz3'

  context 'programmatically disable a feature', ->
    Given -> @ftoggle = @subject.createConfig('2zLAEz3')
    Given -> @ftoggle.disable('fruits')
    Then -> expect(@ftoggle.getPackedConfig()).toBe '2zLaEz3'
