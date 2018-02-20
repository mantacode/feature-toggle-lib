clear = require 'clear-require'

describe 'ftoggle', ->
  Given -> @packer = jasmine.createSpyObj 'packer', ['pack', 'unpack']
  Given -> @subject = require('proxyquire').noCallThru() '../lib/ftoggle',
    './packer': @packer
  
  # Without this, the e2e specs fail when run at the same time (e.g. with
  # the default grunt task) because 'packer' is still stubbed within lib/ftoggle
  afterEach -> clear('../lib/ftoggle')

  describe '.isFeatureEnabled', ->
    Given -> @toggles =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
    Given -> @ftoggle = new @subject(@toggles)

    context 'enabled', ->
      Then -> expect(@ftoggle.isFeatureEnabled('foo.bar')).toBe true

    context 'disabled', ->
      Then -> expect(@ftoggle.isFeatureEnabled('foo.baz')).toBe false

  describe '.findEnabledChildren', ->
    Given -> @toggles =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
          baz:
            e: 1
          quux:
            e: 1
    Given -> @ftoggle = new @subject(@toggles)
    
    context 'with children', ->
      Then -> expect(@ftoggle.findEnabledChildren('foo.bar')).toEqual ['baz', 'quux']

    context 'with no children', ->
      Then -> expect(@ftoggle.findEnabledChildren('foo.bar.baz')).toEqual []
  
    context 'non-existent key', ->
      Then -> expect(@ftoggle.findEnabledChildren('foo.banana')).toEqual []

  describe '.doesFeatureExist', ->
    Given -> @toggles =
      e: 1
      foo:
        e: 1
    Given -> @featureConfig =
      features:
        foo:
          traffic: 1
          features:
            bar:
              traffic: 1
    Given -> @ftoggle = new @subject(@toggles, {}, @featureConfig)

    context 'feature exists', ->
      Then -> expect(@ftoggle.doesFeatureExist('foo.bar')).toBe true

    context 'feature does not exist', ->
      Then -> expect(@ftoggle.doesFeatureExist('foo.quux')).toBe false

  describe '.getToggles', ->
    Given -> @toggles =
      foo: 'bar'
    Given -> @ftoggle = new @subject(@toggles)
    Then -> expect(@ftoggle.getToggles()).toEqual foo: 'bar'

  describe '.getSetting', ->
    Given -> @settings =
      foo: 'bar'
    Given -> @ftoggle = new @subject({}, @settings)

    context 'val exists', ->
      Then -> expect(@ftoggle.getSetting('foo')).toBe 'bar'

    context 'val does not exist', ->
      Then -> expect(@ftoggle.getSetting('banana')).toBe null

  describe '.getSettings', ->
    Given -> @settings =
      foo: 'bar'
    Given -> @ftoggle = new @subject({}, @settings)
    Then -> expect(@ftoggle.getSettings()).toEqual foo: 'bar'

  describe '.enable', ->
    Given -> @toggles =
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
    Given -> @featureConfig =
      name: 'test'
      features:
        foo:
          traffic: 1
          settings:
            banana: true
          features:
            bar:
              traffic: 1
              settings:
                apple: true
            baz:
              traffic: 0
              settings:
                apricot: true
        favoriteFruit:
          traffic: 1
          exclusiveSplit: 1
          features:
            banana:
              traffic: 0.5
              settings:
                yellow: true
            apple:
              traffic: 0.5
              settings:
                red: true
        tree:
          settings:
            maple: true
          traffic: 1
          features:
            trunk:
              settings:
                bark: true
              traffic: 1
    Given -> @settings =
      banana: true
      apple: true
      red: true
    Given -> @ftoggle = new @subject(@toggles, @settings, @featureConfig)

    context 'existing feature', ->
      When -> @ftoggle.enable 'foo.baz'
      Then -> expect(@ftoggle.toggles).toEqual
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
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        apple: true
        apricot: true
        red: true

    context 'non-existent feature', ->
      When -> @ftoggle.enable 'foo.quux'
      Then -> expect(@toggles).toEqual
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
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        apple: true
        red: true

    context 'exclusive split', ->
      When -> @ftoggle.enable 'favoriteFruit.banana'
      Then -> expect(@ftoggle.toggles).toEqual
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
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        apple: true
        yellow: true

    context 'completely new tree path', ->
      When -> @ftoggle.enable 'tree.trunk'
      Then -> expect(@ftoggle.toggles).toEqual
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
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        apple: true
        red: true
        maple: true
        bark: true

  describe '.enableAll', ->
    Given -> @toggles =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
    Given -> @featureConfig =
      name: 'test'
      features:
        foo:
          traffic: 1
          settings:
            banana: true
          features:
            bar:
              traffic: 1
              settings:
                apple: true
            baz:
              traffic: 0
              settings:
                apricot: true
            quux:
              traffic: 0
              settings:
                plum: true
    Given -> @settings =
      banana: true
      apple: true
    Given -> @ftoggle = new @subject(@toggles, @settings, @featureConfig)

    context 'with an array', ->
      When -> @ftoggle.enableAll(['foo.baz', 'foo.quux'])
      Then -> expect(@ftoggle.toggles).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 1
          quux:
            e: 1
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        apple: true
        apricot: true
        plum: true

    context 'with a comma-separated string', ->
      When -> @ftoggle.enableAll('foo.baz,foo.quux')
      Then -> expect(@ftoggle.toggles).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 1
          quux:
            e: 1
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        apple: true
        apricot: true
        plum: true

  describe '.disable', ->
    Given -> @toggles =
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
    Given -> @featureConfig =
      name: 'test'
      features:
        foo:
          traffic: 1
          features:
            bar:
              traffic: 1
              settings:
                banana: true
        tree:
          traffic: 1
          settings:
            maple: true
          features:
            trunk:
              traffic: 1
              settings:
                trunk: true
              features:
                limb:
                  traffic: 1
                  settings:
                    branches: true
    Given -> @settings =
      banana: true
      maple: true
      trunk: true
      branches: true
    Given -> @ftoggle = new @subject(@toggles, @settings, @featureConfig)

    context 'existing feature', ->
      When -> @ftoggle.disable 'foo.bar'
      Then -> expect(@ftoggle.toggles).toEqual
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
      And -> expect(@ftoggle.settings).toEqual
        maple: true
        trunk: true
        branches: true

    context 'non-existent feature', ->
      When -> @ftoggle.disable 'foo.quux'
      Then -> expect(@toggles).toEqual
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
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        maple: true
        trunk: true
        branches: true

    context 'whole tree', ->
      When -> @ftoggle.disable 'tree'
      Then -> expect(@ftoggle.toggles).toEqual
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
      And -> expect(@ftoggle.settings).toEqual
        banana: true

  describe '.disableAll', ->
    Given -> @toggles =
      e: 1
      foo:
        e: 1
        bar:
          e: 1
        baz:
          e: 1
        quux:
          e: 1
    Given -> @featureConfig =
      name: 'test'
      features:
        foo:
          traffic: 1
          settings:
            banana: true
          features:
            bar:
              traffic: 1
              settings:
                apple: true
            baz:
              traffic: 1
              settings:
                apricot: true
            quux:
              traffic: 1
              settings:
                plum: true
    Given -> @settings =
      banana: true
      apple: true
      apricot: true
      plum: true
    Given -> @ftoggle = new @subject(@toggles, @settings, @featureConfig)

    context 'with an array', ->
      When -> @ftoggle.disableAll(['foo.baz', 'foo.quux'])
      Then -> expect(@ftoggle.toggles).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 0
          quux:
            e: 0
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        apple: true

    context 'with a comma-separated string', ->
      When -> @ftoggle.disableAll('foo.baz,foo.quux')
      Then -> expect(@ftoggle.toggles).toEqual
        e: 1
        foo:
          e: 1
          bar:
            e: 1
          baz:
            e: 0
          quux:
            e: 0
      And -> expect(@ftoggle.settings).toEqual
        banana: true
        apple: true

  describe '.serialize', ->
    Given -> @ftoggle = new @subject 'config'
    When -> @ftoggle.serialize()
    Then -> expect(@packer.pack).toHaveBeenCalledWith 'config'

  describe '.deserialize', ->
    When -> @subject.deserialize 'packed', 'settings'
    Then -> expect(@packer.unpack).toHaveBeenCalledWith 'packed', 'settings'
