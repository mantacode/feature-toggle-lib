describe "ftoggle", ->
  Given -> @subject = requireSubject('lib/ftoggle').makeFtoggle()
  Given -> @middleware = @subject.newMiddleware()
  Given -> @res = new FakeHttpResponse()
  Given -> @req = new FakeHttpRequest()
  When -> @middleware(@req, @res, ->)

  describe "req.ftoggle.isFeatureEnabled", ->
    Given -> spyOn(@subject, 'roll').andReturn(0.3)
    
    context "enabled parent, enabled child", ->
      Given -> @subject.setConfig
        features:
          foo:
            traffic: 0.4
            features:
              bar:
                traffic: 0.5
      Then -> @req.ftoggle.isFeatureEnabled('foo.bar') == true
    
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
