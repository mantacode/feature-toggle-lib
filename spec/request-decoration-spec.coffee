describe.only "Request decoration", ->
  Given -> @subject = requireSubject 'lib/request-decoration'

  describe '.isFeatureEnabled', ->
    Given -> @config =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
    Given -> @ftoggle = new @subject(@config)

    context 'enabled', ->
      Then -> expect(@ftoggle.isFeatureEnabled('foo.bar')).toBe true

    context 'disabled', ->
      Then -> expect(@ftoggle.isFeatureEnabled('foo.baz')).toBe false

  describe '.findEnabledChildren', ->
    Given -> @config =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
          baz:
            e: 1
          quux:
            e: 1
    Given -> @ftoggle = new @subject(@config)
    
    context 'with children', ->
      Then -> expect(@ftoggle.findEnabledChildren('foo.bar')).toEqual ['baz', 'quux']

    context 'with no children', ->
      Then -> expect(@ftoggle.findEnabledChildren('foo.bar.baz')).toEqual []
  
    context 'non-existent key', ->
      Then -> expect(@ftoggle.findEnabledChildren('foo.banana')).toEqual []

  describe '.doesFeatureExist', ->
    Given -> @config =
      e: 1
      foo:
        e: 1
    Given -> @toggleConfig =
      features:
        foo:
          traffic: 1
          features:
            bar:
              traffic: 1
    Given -> @ftoggle = new @subject(@config, null, {}, @toggleConfig)

    context 'feature exists', ->
      Then -> expect(@ftoggle.doesFeatureExist('foo.bar')).toBe true

    context 'feature does not exist', ->
      Then -> expect(@ftoggle.doesFeatureExist('foo.quux')).toBe false

  describe '.getFeatures', ->
    Given -> @config =
      foo: 'bar'
    Given -> @ftoggle = new @subject(@config)
    Then -> expect(@ftoggle.getFeatures()).toEqual foo: 'bar'

  describe '.featureVal', ->
    Given -> @featureVals =
      foo: 'bar'
    Given -> @ftoggle = new @subject({}, null, @featureVals)

    context 'val exists', ->
      Then -> expect(@ftoggle.featureVal('foo')).toBe 'bar'

    context 'val does not exist', ->
      Then -> expect(@ftoggle.featureVal('banana')).toBe null

  describe '.getFeatureVals', ->
    Given -> @featureVals =
      foo: 'bar'
    Given -> @ftoggle = new @subject({}, null, @featureVals)
    Then -> expect(@ftoggle.getFeatureVals()).toEqual foo: 'bar'

  describe '.enable', ->
    Given -> @config =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
      favoriteFruit:
        e: 1
        apple:
          e: 1
    Given -> @cookie = jasmine.createSpy 'cookie'
    Given -> @toggleConfig =
      name: 'test'
      cookieOptions: 'blah'
      features:
        foo:
          traffic: 1
          features:
            bar:
              traffic: 1
            baz:
              traffic: 0
        favoriteFruit:
          traffic: 1
          exclusiveSplit: 1
          features:
            banana:
              traffic: 0.5
            apple:
              traffic: 0.5
    Given -> @ftoggle = new @subject(@config, @cookie, {}, @toggleConfig)

    context 'existing feature', ->
      When -> @ftoggle.enable 'foo.baz'
      Then -> expect(@cookie).toHaveBeenCalledWith 'ftoggle-test', JSON.stringify(
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 1
        favoriteFruit:
          e: 1
          apple:
            e: 1
      ), 'blah'

    context 'non-existent feature', ->
      When -> @ftoggle.enable 'foo.quux'
      Then -> expect(@cookie).not.toHaveBeenCalled()
      And -> expect(@config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
        favoriteFruit:
          e: 1
          apple:
            e: 1

    context 'exclusive split', ->
      When -> @ftoggle.enable 'favoriteFruit.banana'
      Then -> expect(@cookie).toHaveBeenCalledWith 'ftoggle-test', JSON.stringify(
        e: 1
        foo:
          e: 1
          bar:
            e: 1
        favoriteFruit:
          e: 1
          banana:
            e: 1
      ), 'blah'

  describe '.disable', ->
    Given -> @config =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
    Given -> @cookie = jasmine.createSpy 'cookie'
    Given -> @toggleConfig =
      name: 'test'
      cookieOptions: 'blah'
      features:
        foo:
          traffic: 1
          features:
            bar:
              traffic: 1
    Given -> @ftoggle = new @subject(@config, @cookie, {}, @toggleConfig)

    context 'existing feature', ->
      When -> @ftoggle.disable 'foo.bar'
      Then -> expect(@cookie).toHaveBeenCalledWith('ftoggle-test', JSON.stringify(
        e: 1
        foo:
          e: 1
      ), 'blah')

    context 'non-existent feature', ->
      When -> @ftoggle.disable 'foo.quux'
      Then -> expect(@cookie).not.toHaveBeenCalled()
      And -> expect(@config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
