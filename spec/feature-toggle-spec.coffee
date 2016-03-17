describe "FeatureToggle config", ->
  Given -> @subject = new (requireSubject 'lib/feature-toggle')
  Given -> @subject.setConfig
    version: 1
    name: 'foo'
    features:
      foo:
        traffic: 1
      bar:
        traffic: 1
  When -> @subject.addConfig
    features:
      foo:
        conf:
          c1: 'val'
  Then -> @subject.toggleConfig.features.foo.conf.c1 == 'val'
  And -> @subject.toggleConfig.features.foo.traffic == 1

describe "FeatureToggle", ->
  Given -> @math = random: jasmine.createSpy("random").andReturn(0.3)

  Given -> @subject = new (requireSubject 'lib/feature-toggle',
    './math': @math
  )
  Given -> @middleware = @subject.newMiddleware()
  Given -> @res = new FakeHttpResponse()
  Given -> @req = new FakeHttpRequest()
  Given -> @req.get = jasmine.createSpy('get').andReturn 'foo.bar.com'
  When -> @middleware(@req, @res, ->)

  describe "req.ftoggle.getFeatures", ->
    Given -> @subject.setConfig
      version: 1
      features:
        foo:
          traffic: 1
    Then -> expect(@req.ftoggle.getFeatures()).toEqual({v:1,e: 1, foo:{e: 1}})

  describe "req.ftoggle.conf", ->
    Given -> @subject.setConfig
      version: 1
      features:
        foo:
          traffic: 1
          conf:
            fooConf: "one"
        bar:
          traffic: 0
          conf:
            barConf: "two"
    Then -> @req.ftoggle.featureVal("fooConf") == "one"
    And  -> @req.ftoggle.featureVal("barConf") == null
    And  -> @req.ftoggle.getFeatureVals()["fooConf"] == "one"

  describe "req.ftoggle.doesFeatureExist", ->
    Given -> @subject.setConfig
      version: 1
      features:
        fool:
          traffic: 0
    Then -> @req.ftoggle.doesFeatureExist('fool') == true
    And -> @req.ftoggle.doesFeatureExist('bar') == false

  describe "req.ftoggle.isFeatureEnabled", ->

    context "enabled parent, enabled child", ->
      Given -> @subject.setConfig
        features:
          foo:
            traffic: 0.4
            features:
              bar:
                traffic: 0.5
      Then -> @req.ftoggle.isFeatureEnabled('foo.bar') == true

    context "missing feature, should return ???", ->
      Given -> @subject.setConfig
        features:
          foo:
            traffic: 0
      Then -> @req.ftoggle.isFeatureEnabled('bar.baz') == false

    context "enabled parent, disabled child", ->
      Given -> @subject.setConfig
        version: 2
        features:
          foo:
            traffic: 0.4
            features:
              bar:
                traffic: 0.2
      Then -> @req.ftoggle.isFeatureEnabled('foo.bar') == false

    context "disabled parent, enabled child", ->
      Given -> @subject.setConfig
        features:
          foo:
            traffic: 0.2
            features:
              barl:
                traffic: 0.8
      Then -> @req.ftoggle.isFeatureEnabled('foo.barl') == false

    context "cookie previously set", ->
      Given -> @subject.setConfig
        name: "foo"
        version: 1
        features:
         foo:
           traffic: 0.6
      Given -> @req.cookies['ftoggle-foo'] = JSON.stringify({e: 1, v: 1})
      Then -> @req.ftoggle.isFeatureEnabled('foo') == false

    context 'old style cookie previously set', ->
      Given -> @subject.setConfig
        name: "foo"
        version: 1
        features:
         foo:
           traffic: 1
      Given -> @req.cookies['ftoggle-foo'] = {enabled: 1, version: 1}
      Then -> @req.ftoggle.isFeatureEnabled('foo') == true
      And -> expect(@res.clearCookie).toHaveBeenCalledWith 'ftoggle-foo', { domain: '.manta.com', path: '/' }

    context "cookie previously set with old version", ->
      Given -> @subject.setConfig
        version: 3
        name: "foo"
        features:
         foo:
           traffic: 0.6
      Given -> @req.cookies['ftoggle-foo'] = JSON.stringify({e: 1, v: 2})
      Then -> @req.ftoggle.isFeatureEnabled('foo') == true

    context "cookie with unsticky", ->
      Given -> @subject.setConfig
        version: 1
        name: "foo"
        features:
          foo:
            traffic: 0.6
            unsticky: 1
      Given -> @req.cookies['ftoggle-foo'] = JSON.stringify({e:1, v:1})
      Then -> @req.ftoggle.isFeatureEnabled('foo') == true

    context "cookie with exclusiveSplit", ->
      Given -> @subject.setConfig
        version: 1
        name: "foo"
        exclusiveSplit: 1
        features:
          bar:
            traffic: 0.5
          baz:
            traffic: 0.5
      Given -> @req.cookies['ftoggle-foo'] = JSON.stringify
        e: 1
        v: 1
        baz:
          e: 1
      Then -> @req.ftoggle.isFeatureEnabled('bar') == false
      And -> @req.ftoggle.isFeatureEnabled('baz') == true

    context "cookie with nested exclusiveSplit", ->
      Given -> @subject.setConfig
        version: 1
        name: "foo"
        exclusiveSplit: 1
        features:
          bar:
            exclusiveSplit: true
            traffic: 0.5
            features:
              quux:
                traffic: 0.5
              bazinga:
                traffic: 0.5
          baz:
            traffic: 0.5
      Given -> @req.cookies['ftoggle-foo'] = JSON.stringify
        e: 1
        v: 1
        bar:
          e: 1
          quux:
            e: 1
      Then -> @req.ftoggle.isFeatureEnabled('baz') == false
      And -> @req.ftoggle.isFeatureEnabled('bar.quux') == true
      And -> @req.ftoggle.isFeatureEnabled('bar') == true
      And -> @req.ftoggle.isFeatureEnabled('bar.bazinga') == false

    context "cookie with nested exclusiveSplit within exclusiveSplit", ->
      Given -> @subject.setConfig
        version: 1
        name: "foo"
        features:
          nestedtest:
            traffic: 1
            exclusiveSplit: true
            features:
              bar:
                exclusiveSplit: true
                traffic: 0.5
                features:
                  quux:
                    traffic: 0.5
                  bazinga:
                    traffic: 0.5
              baz:
                exclusiveSplit: true
                traffic: 0.5
                features:
                  wonderful:
                    traffic: 0.5
                  lovely:
                    traffic: 0.5
      Given -> @req.cookies['ftoggle-foo'] = JSON.stringify
        v: 1
        e: 1
        nestedtest:
          e: 1
          baz:
            e: 1
            wonderful:
              e: 1
      Then -> @req.ftoggle.isFeatureEnabled('nestedtest.baz') == true
      And -> @req.ftoggle.isFeatureEnabled('nestedtest.bar') == false

    context "old cookie with no longer valid split choice (can happen via query param override from bookmark)", ->
      Given -> @subject.setConfig
        version: 1
        name: "foo"
        features:
          nestedtest:
            traffic: 1
            exclusiveSplit: true
            features:
              bar:
                exclusiveSplit: true
                traffic: 0.5
                features:
                  quux:
                    traffic: 0.5
                  bazinga:
                    traffic: 0.5
              baz:
                exclusiveSplit: true
                traffic: 0.5
                features:
                  wonderful:
                    traffic: 0.5
                  lovely:
                    traffic: 0.5
      Given -> @req.query['ftoggle-foo-on'] = 'nestedtest.bam.wonderful'
      Then -> @req.ftoggle.isFeatureEnabled('nestedtest.bam') == false
      And -> (@req.ftoggle.isFeatureEnabled('nestedtest.bar') || @req.ftoggle.isFeatureEnabled('nestedtest.bar')) == true

    context "cookie with unsticky exclusiveSplit", ->
      Given -> @subject.setConfig
        version: 1
        name: "foo"
        features:
          foo:
            exclusiveSplit: 1
            unsticky: 1
            features:
              bar:
                traffic: 0.5
              baz:
                traffic: 0.5
      Given -> @req.cookies['ftoggle-foo'] = JSON.stringify
        v: 1
        e: 1
        foo:
          e: 1
          baz:
            e: 1
      Then -> @req.ftoggle.isFeatureEnabled('foo.bar') == true

    describe "middleware uses query parameters", ->
      context "turns on", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 0
              features:
                baz:
                  traffic: 0
            second:
              traffic: 0
        Given -> @req.query['ftoggle-foo-on'] = 'bar.baz,second'
        Then -> @req.ftoggle.isFeatureEnabled('bar.baz') == true
        And -> @req.ftoggle.isFeatureEnabled('second') == true

      context "turns off", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 1
        Given -> @req.query['ftoggle-foo-off'] = 'bar'
        Then -> @req.ftoggle.isFeatureEnabled('bar') == false

      context "honors exclusiveSplit", ->
        Given -> @subject.setConfig
          name: "foo"
          exclusiveSplit: true
          features:
            bar:
              traffic: .5
            baz:
              traffic: .5

        context "turn on", ->
          Given -> @req.query['ftoggle-foo-on'] = 'baz'
          Then -> @req.ftoggle.isFeatureEnabled('bar') == false

        context "turn off", ->
          Given -> @req.query['ftoggle-foo-off'] = 'bar'
          Then -> @req.ftoggle.isFeatureEnabled('bar') == false
          And -> @req.ftoggle.isFeatureEnabled('baz') == false

      context "two-level exclusiveSplit, toplevel off", ->
        Given -> @subject.setConfig
          name: "foo"
          exclusiveSplit: true
          features:
            bar:
              traffic: .2
              exclusiveSplit: true
              features:
                bar1:
                  traffic: .5
                bar2:
                  traffic: .5
            baz:
              traffic: .8
        Then -> @req.ftoggle.isFeatureEnabled('bar.bar1') == false
        And  -> @req.ftoggle.isFeatureEnabled('bar.bar2') == false

      context "two-level exclusiveSplit, toplevel on", ->
        Given -> @subject.setConfig
          name: "foo"
          exclusiveSplit: true
          features:
            bar:
              traffic: .5
              exclusiveSplit: true
              features:
                bar1:
                  traffic: .5
                bar2:
                  traffic: .5
            baz:
              traffic: .8
        Then -> @req.ftoggle.isFeatureEnabled('bar.bar1') == true
        And  -> @req.ftoggle.isFeatureEnabled('bar.bar2') == false

      context "applyToggles doesn't murder non-exclusive features", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 1
            baz:
              traffic: 1
        Given -> @req.query['ftoggle-foo-on'] = 'bar'
        Then -> @req.ftoggle.isFeatureEnabled('bar') == true
        And -> @req.ftoggle.isFeatureEnabled('baz') == true

      context 'overrides cookie', ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 1
        Given -> @req.cookies['ftoggle-foo'] = JSON.stringify
          e: 1
          v: 1
          bar:
            e: 1
        Given -> @req.query['ftoggle-foo-off'] = 'bar'
        Then -> @req.ftoggle.isFeatureEnabled('bar') == false

    describe "header toggles feature", ->
      context "turns on", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 0
              features:
                baz:
                  traffic: 0
            second:
              traffic: 0
        Given -> @req.headers['x-ftoggle-foo-on'] = 'bar.baz,second'
        Then -> @req.ftoggle.isFeatureEnabled('bar.baz') == true
        And -> @req.ftoggle.isFeatureEnabled('second') == true

      context "turns off", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 1
        Given -> @req.headers['x-ftoggle-foo-off'] = 'bar'
        Then -> @req.ftoggle.isFeatureEnabled('bar') == false

      context "overridden by query parameter", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 0
              features:
                baz:
                  traffic: 0
            second:
              traffic: 0
        Given -> @req.headers['x-ftoggle-foo-on'] = 'bar.baz,second'
        Given -> @req.query['ftoggle-foo-off'] = 'bar'
        Then -> @req.ftoggle.isFeatureEnabled('bar') == false

      context "overridden by query parameter with treatment that doesn't exist", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 0
              features:
                baz:
                  traffic: 0
            second:
              traffic: 0
        Given -> @req.query['ftoggle-foo-on'] = 'fluffy'
        Then -> @req.ftoggle.isFeatureEnabled('fluffy') == false


  describe "#findEnabledChildren", ->
    context "returns empty list for no results", ->
      Given -> @subject.setConfig
        features:
          a:
            traffic: 0
      Then -> @req.ftoggle.findEnabledChildren().length == 0

    context "top level (no prefix)", ->
      Given -> @subject.setConfig
        features:
          a:
            traffic: 1
          b:
            traffic: 0
      Then -> @req.ftoggle.findEnabledChildren().length == 1
      And -> @req.ftoggle.findEnabledChildren()[0] == 'a'
    context "second level (prefix)", ->
      Given -> @subject.setConfig
        features:
          a:
            traffic: 1
            features:
              c:
                traffic: 1
              d:
                traffic: 1
      Then -> @req.ftoggle.findEnabledChildren('a').length == 2

  describe "exclusive split", ->
    context "always return 1", ->
      Given -> @subject.setConfig
        exclusiveSplit: true
        features:
          a:
            traffic: 0.9
          b:
            traffic: 0.9
      Then ->
        @req.ftoggle.findEnabledChildren().length == 1

    context "return the correct one", ->
      Given -> @subject.setConfig
        exclusiveSplit: true
        features:
          a:
            traffic: 0.2
          b:
            traffic: 0.8
      Then ->
        @req.ftoggle.findEnabledChildren()[0] == 'b'

    context "no traffic set, no winner", ->
      Given -> @subject.setConfig
        exclusiveSplit: true
        features:
          a: {}
          b: {}
      Then ->
        @req.ftoggle.findEnabledChildren().length == 0

    context "mixed traffic and no traffic", ->
      Given -> @subject.setConfig
        exclusiveSplit: true
        features:
          a:
            traffic: 0.2
          b:
            traffic: 0.8
          c: {}
      Then ->
        @req.ftoggle.findEnabledChildren()[0] == 'b'

    context "a bot user", ->
      Given -> @req.headers['x-bot'] = '1'
      Given -> @subject.setConfig
        exclusiveSplit: true
        features:
          a:
            traffic: 1
            botTraffic: 0
            exclusiveSplit: true
            features:
              c:
                traffic: 0
              d:
                traffic: 1
          b:
            traffic: 0
            botTraffic: 1
            exclusiveSplit: true
            features:
              e:
                traffic: 0
              f:
                traffic: 1
      Then -> @req.ftoggle.findEnabledChildren()[0] == 'b'
      And -> @req.ftoggle.findEnabledChildren('a').length == 0
      And -> @req.ftoggle.findEnabledChildren('b')[0] == 'f'

  describe "middleware sets cookie", ->
    Given -> @subject.setConfig
      name: "foo"
      version: 2
      features:
        foo:
          traffic: 1
    When -> @cookie = JSON.parse(@res.cookies['ftoggle-foo'])
    Then -> expect(@cookie.foo).toEqual
      e: 1
    And -> @cookie.v == 2

    context "with cookie options", ->
      Given -> @subject.setConfig
        name: "foo"
        version: 2
        features:
          foo:
            traffic: 1
        cookieOptions:
          domain: 'my.domain.com'
          expires: 'my expires'
          madeUpOption: 'this is fake'
      When -> @cookie = JSON.parse(@res.cookies['ftoggle-foo'])
      Then -> expect(@cookie.foo).toEqual
        e: 1
      And -> @cookie.v == 2
      And -> expect(@res.cookies['ftoggle-foo--options']).toEqual
        domain: 'my.domain.com'
        expires: 'my expires'
        madeUpOption: 'this is fake'
        maxAge: 63072000000
        path: '/'

    context 'with defaults', ->
      Given -> @subject.setConfig
        name: "foo"
        version: 2
        features:
          foo:
            traffic: 1
        cookieOptions: {}
      When -> @cookie = JSON.parse(@res.cookies['ftoggle-foo'])
      Then -> expect(@cookie.foo).toEqual
        e: 1
      And -> @cookie.v == 2
      And -> expect(@res.cookies['ftoggle-foo--options']).toEqual
        domain: '.bar.com'
        maxAge: 63072000000
        path: '/'
