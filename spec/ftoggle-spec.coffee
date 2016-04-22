describe 'ftoggle', ->
  Given -> @subject = requireSubject 'lib/ftoggle'

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
    Given -> @ftoggle = new @subject(@config, {}, @toggleConfig)

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
    Given -> @ftoggle = new @subject({}, @featureVals)

    context 'val exists', ->
      Then -> expect(@ftoggle.featureVal('foo')).toBe 'bar'

    context 'val does not exist', ->
      Then -> expect(@ftoggle.featureVal('banana')).toBe null

  describe '.getFeatureVals', ->
    Given -> @featureVals =
      foo: 'bar'
    Given -> @ftoggle = new @subject({}, @featureVals)
    Then -> expect(@ftoggle.getFeatureVals()).toEqual foo: 'bar'

  describe '.enable', ->
    Given -> @config =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
        baz:
          e: 0
      favoriteFruit:
        e: 1
        apple:
          e: 1
        banana:
          e: 0
      tree:
        e: 0
        trunk:
          e: 0
    Given -> @toggleConfig =
      name: 'test'
      cookieOptions: 'blah'
      features:
        foo:
          traffic: 1
          conf:
            banana: true
          features:
            bar:
              traffic: 1
              conf:
                apple: true
            baz:
              traffic: 0
              conf:
                apricot: true
        favoriteFruit:
          traffic: 1
          exclusiveSplit: 1
          features:
            banana:
              traffic: 0.5
              conf:
                yellow: true
            apple:
              traffic: 0.5
              conf:
                red: true
        tree:
          conf:
            maple: true
          traffic: 1
          features:
            trunk:
              conf:
                bark: true
              traffic: 1
    Given -> @featureVals =
      banana: true
      apple: true
      red: true
    Given -> @ftoggle = new @subject(@config, @featureVals, @toggleConfig)

    context 'existing feature', ->
      When -> @ftoggle.enable 'foo.baz'
      Then -> expect(@ftoggle.config).toEqual
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
          banana:
            e: 0
        tree:
          e: 0
          trunk:
            e: 0
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        apple: true
        apricot: true
        red: true

    context 'non-existent feature', ->
      When -> @ftoggle.enable 'foo.quux'
      Then -> expect(@config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 0
        favoriteFruit:
          e: 1
          apple:
            e: 1
          banana:
            e: 0
        tree:
          e: 0
          trunk:
            e: 0
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        apple: true
        red: true

    context 'exclusive split', ->
      When -> @ftoggle.enable 'favoriteFruit.banana'
      Then -> expect(@ftoggle.config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 0
        favoriteFruit:
          e: 1
          apple:
            e: 0
          banana:
            e: 1
        tree:
          e: 0
          trunk:
            e: 0
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        apple: true
        yellow: true

    context 'completely new tree path', ->
      When -> @ftoggle.enable 'tree.trunk'
      Then -> expect(@ftoggle.config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 0
        favoriteFruit:
          e: 1
          apple:
            e: 1
          banana:
            e: 0
        tree:
          e: 1
          trunk:
            e: 1
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        apple: true
        red: true
        maple: true
        bark: true

  describe '.enableAll', ->
    Given -> @config =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
    Given -> @toggleConfig =
      name: 'test'
      cookieOptions: 'blah'
      features:
        foo:
          traffic: 1
          conf:
            banana: true
          features:
            bar:
              traffic: 1
              conf:
                apple: true
            baz:
              traffic: 0
              conf:
                apricot: true
            quux:
              traffic: 0
              conf:
                plum: true
    Given -> @featureVals =
      banana: true
      apple: true
    Given -> @ftoggle = new @subject(@config, @featureVals, @toggleConfig)

    context 'with an array', ->
      When -> @ftoggle.enableAll(['foo.baz', 'foo.quux'])
      Then -> expect(@ftoggle.config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 1
          quux:
            e: 1
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        apple: true
        apricot: true
        plum: true

    context 'with a comma-separated string', ->
      When -> @ftoggle.enableAll('foo.baz,foo.quux')
      Then -> expect(@ftoggle.config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 1
          quux:
            e: 1
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        apple: true
        apricot: true
        plum: true

  describe '.disable', ->
    Given -> @config =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
      tree:
        e: 1
        trunk:
          e: 1
          limb:
            e: 1
    Given -> @toggleConfig =
      name: 'test'
      cookieOptions: 'blah'
      features:
        foo:
          traffic: 1
          features:
            bar:
              traffic: 1
              conf:
                banana: true
        tree:
          traffic: 1
          conf:
            maple: true
          features:
            trunk:
              traffic: 1
              conf:
                trunk: true
              features:
                limb:
                  traffic: 1
                  conf:
                    branches: true
    Given -> @featureVals =
      banana: true
      maple: true
      trunk: true
      branches: true
    Given -> @ftoggle = new @subject(@config, @featureVals, @toggleConfig)

    context 'existing feature', ->
      When -> @ftoggle.disable 'foo.bar'
      Then -> expect(@ftoggle.config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 0
        tree:
          e: 1
          trunk:
            e: 1
            limb:
              e: 1
      And -> expect(@ftoggle.featureVals).toEqual
        maple: true
        trunk: true
        branches: true

    context 'non-existent feature', ->
      When -> @ftoggle.disable 'foo.quux'
      Then -> expect(@config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
        tree:
          e: 1
          trunk:
            e: 1
            limb:
              e: 1
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        maple: true
        trunk: true
        branches: true

    context 'whole tree', ->
      When -> @ftoggle.disable 'tree'
      Then -> expect(@ftoggle.config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
        tree:
          e: 0
          trunk:
            e: 0
            limb:
              e: 0
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true

  describe '.disableAll', ->
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
    Given -> @toggleConfig =
      name: 'test'
      cookieOptions: 'blah'
      features:
        foo:
          traffic: 1
          conf:
            banana: true
          features:
            bar:
              traffic: 1
              conf:
                apple: true
            baz:
              traffic: 1
              conf:
                apricot: true
            quux:
              traffic: 1
              conf:
                plum: true
    Given -> @featureVals =
      banana: true
      apple: true
      apricot: true
      plum: true
    Given -> @ftoggle = new @subject(@config, @featureVals, @toggleConfig)

    context 'with an array', ->
      When -> @ftoggle.disableAll(['foo.baz', 'foo.quux'])
      Then -> expect(@ftoggle.config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 0
          quux:
            e: 0
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        apple: true

    context 'with a comma-separated string', ->
      When -> @ftoggle.disableAll('foo.baz,foo.quux')
      Then -> expect(@ftoggle.config).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 0
          quux:
            e: 0
      And -> expect(@ftoggle.featureVals).toEqual
        banana: true
        apple: true
