describe.only 'add', ->
  context 'top level feature', ->
    When (done) -> runCmd('ftoggle add banana', __dirname, done)
    And -> @foo = require './ftoggle.foo'
    And -> @bar = require './ftoggle.bar'
    Then -> expect(@foo.features).toEqual @bar.features
    And -> expect(@foo.features).toEqual
      banana:
        traffic: 0

  context 'nested feature with enable', ->
    When (done) -> runCmd('ftoggle add fruits.banana -E foo', __dirname, done)
    And -> @foo = require './ftoggle.foo'
    And -> @bar = require './ftoggle.bar'
    Then -> expect(@foo.features).toEqual
      fruits:
        traffic: 1
        features:
          banana:
            traffic: 1
    And -> expect(@bar.features).toEqual
      fruits:
        traffic: 0
        features:
          banana:
            traffic: 0

  context 'enable all', ->
    When (done) -> runCmd('ftoggle add banana -E', __dirname, done)
    And -> @foo = require './ftoggle.foo'
    And -> @bar = require './ftoggle.bar'
    Then -> expect(@foo.features).toEqual @bar.features
    And -> expect(@foo.features).toEqual
      banana:
        traffic: 1

  context 'enable with multiple flags', ->
    When (done) -> runCmd('ftoggle add banana -E foo -E bar', __dirname, done)
    And -> @foo = require './ftoggle.foo'
    And -> @bar = require './ftoggle.bar'
    Then -> expect(@foo.features).toEqual @bar.features
    And -> expect(@foo.features).toEqual
      banana:
        traffic: 1

  context 'enable with comma separated list', ->
    When (done) -> runCmd('ftoggle add banana -E foo,bar', __dirname, done)
    And -> @foo = require './ftoggle.foo'
    And -> @bar = require './ftoggle.bar'
    Then -> expect(@foo.features).toEqual @bar.features
    And -> expect(@foo.features).toEqual
      banana:
        traffic: 1

  context 'enable with multiple flags, bump, stage, and commit', ->
    When (done) -> runCmd('ftoggle add banana -bsc -E foo -E bar', __dirname, done)
    And -> @foo = require './ftoggle.foo'
    And -> @bar = require './ftoggle.bar'
    Then -> expect(@foo.features).toEqual @bar.features
    And -> expect(@foo.features).toEqual
      banana:
        traffic: 1
    And -> expect(@foo.version).toEqual 2
    And (done) ->
      ftoggleDiff (err, diff) ->
        expect(diff).toContain chalk.green('+ "version": 2, + "features": { + "banana": { + "traffic": 1 + } + } +}')
        done()
