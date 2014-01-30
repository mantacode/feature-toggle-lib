describe "FeatureToggle", ->
  Given -> @math = random: jasmine.createSpy("random").andReturn(0.3)

  Given -> @subject = new (requireSubject 'lib/feature-toggle',
    './math': @math
  )
  Given -> @middleware = @subject.newMiddleware()
  Given -> @res = new FakeHttpResponse()
  Given -> @req = new FakeHttpRequest()
  When -> @middleware(@req, @res, ->)

  describe "req.ftoggle.getFeatures", ->
    Given -> @subject.setConfig
      version: 1
      features:
        foo:
          traffic: 1
    Then -> expect(@req.ftoggle.getFeatures()).toEqual({version:1,enabled: true, foo:{enabled: true}});

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
              bar:
                traffic: 0.8
      Then -> @req.ftoggle.isFeatureEnabled('foo.bar') == false

    context "cookie previously set", ->
      Given -> @subject.setConfig
        name: "foo"
        features:
         foo:
           traffic: 0.6
      Given -> @req.cookies['ftoggle-foo'] =
        foo:
         enabled: false
      Then -> @req.ftoggle.isFeatureEnabled('foo') == false

    context "cookie previously set with old version", ->
      Given -> @subject.setConfig
        version: 3
        name: "foo"
        features:
         foo:
           traffic: 0.6
      Given -> @req.cookies['ftoggle-foo'] =
        version: 2
        foo:
         enabled: false
      Then -> @req.ftoggle.isFeatureEnabled('foo') == true

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
        Given -> @req.params['ftoggle-foo-on'] = 'bar.baz,second'
        Then -> @req.ftoggle.isFeatureEnabled('bar.baz') == true
        And -> @req.ftoggle.isFeatureEnabled('second') == true
      context "turns off", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 1
        Given -> @req.params['ftoggle-foo-off'] = 'bar'
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
          Given -> @req.params['ftoggle-foo-on'] = 'baz'
          Then -> @req.ftoggle.isFeatureEnabled('bar') == false
        context "turn off", ->
          Given -> @req.params['ftoggle-foo-off'] = 'bar'
          Then -> @req.ftoggle.isFeatureEnabled('bar') == false
          And -> @req.ftoggle.isFeatureEnabled('baz') == false

      context "applyToggles doesn't murder non-exclusive features", ->
        Given -> @subject.setConfig
          name: "foo"
          features:
            bar:
              traffic: 1
            baz:
              traffic: 1
        Given -> @req.params['ftoggle-foo-on'] = 'bar'
        Then -> @req.ftoggle.isFeatureEnabled('bar') == true
        Then -> @req.ftoggle.isFeatureEnabled('baz') == true

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

  describe "middleware sets cookie", ->
    Given -> @subject.setConfig
      name: "foo"
      version: 2
      features:
        foo:
          traffic: 1
    Then -> expect(@res.cookies['ftoggle-foo'].foo).toEqual
      enabled: true
    And -> @res.cookies['ftoggle-foo'].version == 2


