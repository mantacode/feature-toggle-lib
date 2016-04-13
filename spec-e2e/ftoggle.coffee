app = require('./fixtures/app.js')
request = require('supertest')
req = request(app)
_ = require('lodash')

describe.only 'ftoggle', ->
  context 'sets config', ->
    Given -> @config = require('./fixtures/config.js')
    Given (done) -> req.get('/ftoggle-config').end (@err, @res) => done()
    Then -> expect(JSON.parse(@res.text)).toEqual @config

  context 'sets toggles based on traffic', ->
    Given (done) -> req.get('/user-config').end (@err, @res) => done()
    When -> @config = JSON.parse(@res.text)
    Then -> expect(@config.e).toBe 1
    And -> expect(@config.v).toBe 2
    And -> expect(@config.foo).toEqual e: 1
    And -> expect(@config.treatments.e).toBe 1
    And -> expect(@config.treatments).toHaveOneEnabled 'treatment_a', 'treatment_b'

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
    Given -> @config =
      e: 1
      v: 2
      foo:
        e: 1
      bar:
        e: 1
    Given (done) ->
      req.get('/user-config')
        .set('Cookie', "ftoggle-test=#{JSON.stringify(@config)}")
        .end (@err, @res) => done()
    Then -> expect(JSON.parse(@res.text)).toEqual @config

  context 'does not use old cookie', ->
    Given -> @config =
      e: 1
      v: 1
      foo:
        e: 1
      bar:
        e: 1
    Given (done) ->
      req.get('/user-config')
        .set('Cookie', "ftoggle-test=#{JSON.stringify(@config)}")
        .end (@err, @res) => done()
    Then -> expect(JSON.parse(@res.text)).not.toEqual @config

  context 'with a cookie, overridden by query', ->
    Given -> @config =
      e: 1
      v: 2
      foo:
        e: 1
      bar:
        e: 1
    Given (done) ->
      req.get('/user-config?ftoggle-test-on=treatments.treatment_a,fruits.banana.yellow_banana&ftoggle-test-off=bar')
        .set('Cookie', "ftoggle-test=#{JSON.stringify(@config)}")
        .end (@err, @res) => done()
    Then -> expect(JSON.parse(@res.text)).toEqual
      e: 1
      v: 2
      foo:
        e: 1
      treatments:
        e: 1
        treatment_a:
          e: 1
      fruits:
        e: 1
        banana:
          e: 1
          yellow_banana:
            e: 1

  context 'programmatically enable a feature', ->
    Given -> @config =
      e: 1
      v: 2
      foo:
        e: 1
      bar:
        e: 1
    Given (done) ->
      req.get('/enable/fruits')
        .set('Cookie', "ftoggle-test=#{JSON.stringify(@config)}")
        .end (@err, @res) => done()
    Given -> @headerNames = []
    Given -> @headers = _.reduce @res.headers['set-cookie'], (memo, cookie) =>
      parts = cookie.split(';')[0].split('=')
      @headerNames.push( parts[0] )
      memo[ parts[0] ] = JSON.parse(decodeURIComponent(parts[1]))
      return memo
    , {}
    Then -> expect(@headers['ftoggle-test']).toEqual
      e: 1
      v: 2
      foo:
        e: 1
      bar:
        e: 1
      fruits:
        e: 1
    And -> expect(_.filter(@headerNames, (h) -> h == 'ftoggle-test').length).toBe 1

  context 'programmatically disable a feature', ->
    Given -> @config =
      e: 1
      v: 2
      foo:
        e: 1
      bar:
        e: 1
    Given (done) ->
      req.get('/disable/bar')
        .set('Cookie', "ftoggle-test=#{JSON.stringify(@config)}")
        .end (@err, @res) => done()
    Given -> @headers = _.reduce @res.headers['set-cookie'], (memo, cookie) ->
      parts = cookie.split(';')[0].split('=')
      memo[ parts[0] ] = JSON.parse(decodeURIComponent(parts[1]))
      return memo
    , {}
    Then -> expect(@headers['ftoggle-test']).toEqual
      e: 1
      v: 2
      foo:
        e: 1
