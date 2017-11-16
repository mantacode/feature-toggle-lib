app = require('./fixtures/app.js')
request = require('supertest')
req = request(app)
_ = require('lodash')

describe 'ftoggle', ->
  Given -> @getFtoggleCookie = (res) ->
    res.headers['set-cookie'][0].split(';')[0].split('=')[1]

  context 'sets config', ->
    Given -> @config = require('./fixtures/final.js')
    Given (done) -> req.get('/ftoggle-config').end (@err, @res) => done()
    Given -> @cookie = @getFtoggleCookie(@res)
    Then -> expect(JSON.parse(@res.text)).toEqual @config
    And -> expect(['2zLaEz3', '2zLaFz3']).toContain @cookie

  context 'sets toggles based on traffic', ->
    Given (done) -> req.get('/user-config').end (@err, @res) => done()
    When -> @config = JSON.parse(@res.text)
    Then -> expect(@config.e).toBe 1
    And -> expect(@config.v).toBe 2
    And -> expect(@config.foo).toEqual e: 1
    And -> expect(@config.treatments.e).toBe 1
    And -> expect(@config.treatments.treatment_a.e + @config.treatments.treatment_b.e).toBe 1

  context 'sets features', ->
    Given (done) -> req.get('/features').end (@err, @res) => done()
    When -> @features = JSON.parse(@res.text)
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
      Given (done) -> req.get('/isFeatureEnabled/foo').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual enabled: true

    context 'returns true for enabled features', ->
      Given (done) -> req.get('/isFeatureEnabled/bar').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual enabled: false

  context 'findEnabledChildren', ->
    context 'top level', ->
      Given (done) -> req.get('/findEnabledChildren').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual ['foo', 'treatments']

    context 'lower level', ->
      Given (done) -> req.get('/findEnabledChildren/treatments').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toContainOneOf 'treatment_a', 'treatment_b'

  context 'doesFeatureExist', ->
    context 'existing and enabled feature', ->
      Given (done) -> req.get('/doesFeatureExist/foo').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual exists: true

    context 'existing and disabled feature', ->
      Given (done) -> req.get('/doesFeatureExist/bar').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual exists: true

    context 'nested feaure', ->
      Given (done) -> req.get('/doesFeatureExist/treatments.treatment_a').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual exists: true

    context 'non-existent feature', ->
      Given (done) -> req.get('/doesFeatureExist/chicken').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual exists: false

  context 'featureVal', ->
    context 'feature is set', ->
      Given (done) -> req.get('/featureVal/fooEnabled').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual val: true

    context 'feature is unset', ->
      Given (done) -> req.get('/featureVal/barEnabled').end (@err, @res) => done()
      Then -> expect(JSON.parse(@res.text)).toEqual val: null

  context 'uses current cookie', ->
    Given (done) ->
      req.get('/user-config')
        .set('Cookie', "ftoggle-test=2zLaEz3")
        .end (@err, @res) => done()
    Then -> expect(JSON.parse(@res.text)).toEqual
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
    Given (done) ->
      req.get('/user-config')
        .set('Cookie', "ftoggle-test=1zLaEz3")
        .end (@err, @res) => done()
    Given -> @cookie = @getFtoggleCookie(@res)
    Then -> expect(@cookie).not.toEqual '1zLaEz3'

  context 'with a cookie, overridden by query', ->
    Given (done) ->
      req.get('/user-config?ftoggle-test-on=treatments.treatment_a,fruits.banana.yellow_banana&ftoggle-test-off=bar')
        .set('Cookie', "ftoggle-test=2zLaEz3")
        .end (@err, @res) => done()
    Given -> @cookie = @getFtoggleCookie(@res)
    Then -> expect(@cookie).toEqual '2zLKFz3'

  context 'programmatically enable a feature', ->
    Given (done) ->
      req.get('/enable/fruits')
        .set('Cookie', "ftoggle-test=2zLaEz3")
        .end (@err, @res) => done()
    Given -> @cookie = @getFtoggleCookie(@res)
    Then -> expect(@cookie).toBe '2zLAEz3'
    And -> expect(@res.headers['set-cookie'].length).toBe 1

  context 'programmatically disable a feature', ->
    Given (done) ->
      req.get('/disable/fruits')
        .set('Cookie', "ftoggle-test=2zLAEz3")
        .end (@err, @res) => done()
    Given -> @cookie = @getFtoggleCookie(@res)
    Then -> expect(@cookie).toBe '2zLaEz3'
