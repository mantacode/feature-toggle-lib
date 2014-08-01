describe 'add', ->
  context 'top level feature', ->
    When (done) -> runCmd('ftoggle add banana', __dirname, done)
    And -> @foo = require './ftoggle.foo'
    And -> @bar = require './ftoggle.bar'
    Then -> expect(@foo.features).toEqual @bar.features
    And -> expect(@foo.features).toEqual
      banana:
        traffic: 1
