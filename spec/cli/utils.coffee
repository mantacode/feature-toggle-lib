_ = require 'underscore'
EventEmitter = require('events').EventEmitter
chalk = require 'chalk'
path = require 'path'

describe 'cli utils', ->
  Given -> @resolve = jasmine.createSpyObj 'resolve', ['sync']
  Given -> @path = jasmine.createSpyObj 'path', ['resolve', 'dirname', 'normalize']
  Given -> @fs = jasmine.createSpyObj 'fs', ['writeFile']
  Given -> @cp = jasmine.createSpyObj 'child_process', ['spawn']
  Given -> @readline = jasmine.createSpyObj 'readline', ['createInterface']
  Given -> @subject = requireSubject 'cli/utils',
    resolve: @resolve
    path: @path
    'foo file': 'foo exports'
    'bar file': 'bar exports'
    underscore: _
    fs: @fs
    child_process: @cp
    readline: @readline

  describe '.getInterface', ->
    Given -> @readline.createInterface.when(jasmine.any(Object)).thenReturn 'interface'
    Then -> expect(@subject.getInterface()).toBe 'interface'

  describe '.closeInterface', ->
    Given -> @rl = jasmine.createSpyObj 'rl', ['close']
    Given -> @readline.createInterface.andReturn @rl
    When -> @subject.getInterface()
    And -> @subject.closeInterface()
    Then -> expect(@rl.close).toHaveBeenCalled()

  describe '.writeBlock', ->
    Given -> spyOn console, 'log'
    When -> @subject.writeBlock 'foo', 'bar'
    Then -> expect(_(console.log.calls).pluck('args')).toEqual [
      [], ['  ', 'foo'], ['  ', 'bar'], []
    ]

  describe '.getRoot', ->
    context 'ftoggle installed', ->
      Given -> @resolve.sync.when('ftoggle/package.json', { basedir: process.cwd() }).thenReturn 'resolved'
      Given -> @path.dirname.when('resolved').thenReturn 'dirnamed'
      Given -> @path.resolve.when('dirnamed', '..', '..').thenReturn 'absolute path'
      When -> @res = @subject.getRoot()
      Then -> expect(@res).toBe 'absolute path'

    context 'ftoggle not installed', ->
      Given -> spyOn @subject, 'exit'
      Given -> spyOn @subject, 'writeBlock'
      Given -> @resolve.sync.when('ftoggle/package.json', { basedir: process.cwd() }).thenCallFake -> throw new Error('HOLY ERROR BATMAN!')
      When -> @subject.getRoot()
      Then -> expect(@subject.writeBlock).toHaveBeenCalledWith chalk.red('Unable to locate local ftoggle installation.'), "Run #{chalk.gray('npm install ftoggle --save')} followed by #{chalk.gray('ftoggle init')} to get started."
      And -> expect(@subject.exit).toHaveBeenCalled()

  describe '.fromRoot', ->
    # Call thru to the real normalize
    Given -> @path.normalize.andCallFake path.normalize
    Given -> spyOn(@subject, 'getRoot').andReturn '/foo/bar'
    context 'does not end in slash', ->
      When -> @p = @subject.fromRoot './config'
      Then -> expect(@p).toBe '/foo/bar/config'

    context 'ends in slash', ->
      When -> @p = @subject.fromRoot './config/'
      Then -> expect(@p).toBe '/foo/bar/config'

  describe '.exit', ->
    Given -> spyOn process, 'exit'
    Given -> spyOn @subject, 'writeBlock'

    context 'no error', ->
      When -> @subject.exit()
      Then -> expect(process.exit).toHaveBeenCalledWith(0)

    context 'error', ->
      When -> @subject.exit('err')
      Then -> expect(@subject.writeBlock).toHaveBeenCalledWith 'err'
      And -> expect(process.exit).toHaveBeenCalledWith 1

  #describe '.expand', ->
    #context 'no exclusive split', ->
      #Given -> @obj = {}
      #When -> @subject.expand @obj, 'foo.bar.baz', { traffic: 1 }
      #Then -> expect(@obj).toEqual
        #foo:
          #traffic: 1
          #features:
            #bar:
              #traffic: 1
              #features:
                #baz:
                  #traffic: 1

      #context 'with exclusive split', ->
        #context 'plan: on', ->
          #Given -> @obj =
            #foo:
              #exclusiveSplit: true
              #traffic: 1
              #features:
                #bar:
                  #traffic: 0.25
                #baz:
                  #traffic: 0.25
                #quux:
                  #traffic: 0.25
                #blah:
                  #traffic: 0.25
          #When -> @subject.expand @obj, 'foo.bazinga', { traffic: 1 }, 'on'
          #Then -> expect(@obj).toEqual
            #foo:
              #exclusiveSplit: true
              #traffic: 1
              #features:
                #bar:
                  #traffic: 0
                #baz:
                  #traffic: 0
                #quux:
                  #traffic: 0
                #blah:
                  #traffic: 0
                #bazinga:
                  #traffic: 1

        #context 'plan: off', ->
          #Given -> @obj =
            #foo:
              #exclusiveSplit: true
              #traffic: 1
              #features:
                #bar:
                  #traffic: 0.25
                #baz:
                  #traffic: 0.25
                #quux:
                  #traffic: 0.25
                #blah:
                  #traffic: 0.25
          #When -> @subject.expand @obj, 'foo.bazinga', { traffic: 1 }, 'off'
          #Then -> expect(@obj).toEqual
            #foo:
              #exclusiveSplit: true
              #traffic: 1
              #features:
                #bar:
                  #traffic: 0.25
                #baz:
                  #traffic: 0.25
                #quux:
                  #traffic: 0.25
                #blah:
                  #traffic: 0.25
                #bazinga:
                  #traffic: 0
        
        #context 'plan: split', ->
          #Given -> @obj =
            #foo:
              #exclusiveSplit: true
              #traffic: 1
              #features:
                #bar:
                  #traffic: 0.25
                #baz:
                  #traffic: 0.25
                #quux:
                  #traffic: 0.25
                #blah:
                  #traffic: 0.25
          #When -> @subject.expand @obj, 'foo.bazinga', { traffic: 1 }, 'on'
          #Then -> expect(@obj).toEqual
            #foo:
              #exclusiveSplit: true
              #traffic: 1
              #features:
                #bar:
                  #traffic: 0.2
                #baz:
                  #traffic: 0.2
                #quux:
                  #traffic: 0.2
                #blah:
                  #traffic: 0.2
                #bazinga:
                  #traffic: 0.2

  describe '.bump', ->
    Given -> @options =
      environments: ['banana', 'pear']
      modified: ['apple']
      ftoggle:
        banana:
          config:
            version: 2
        pear:
          config:
            version: 3
    Given -> @cb = jasmine.createSpy 'cb'
    
    context 'no version set', ->
      When -> @subject.bump.apply @options, ['feature', 'traffic', 'banana', @cb]
      Then -> expect(@options.ftoggle.banana.config.version).toEqual 4
      And -> expect(@options.modified).toEqual ['apple', 'banana']
      And -> expect(@cb).toHaveBeenCalledWith null, 'feature', 'traffic', 'banana'

    context 'version set', ->
      Given -> @options.ftoggleVersion = 7
      When -> @subject.bump.apply @options, ['feature', 'traffic', 'banana', @cb]
      Then -> expect(@options.ftoggle.banana.config.version).toEqual 7
      And -> expect(@options.modified).toEqual ['apple', 'banana']
      And -> expect(@cb).toHaveBeenCalledWith null, 'feature', 'traffic', 'banana'
      

  describe '.write', ->
    Given -> spyOn(@subject, 'fromRoot').andCallFake (p) -> "root/#{p}"
    Given -> @options =
      configDir: 'config'
      ftoggle:
        banana:
          config:
            version: 1
    Given -> @cb = jasmine.createSpy 'cb'
    Given -> @fs.writeFile.andCallFake (path, obj, cb) -> cb()
    When -> @subject.write.apply @options, ['feature', 'traffic', 'banana', @cb]
    Then -> expect(@fs.writeFile).toHaveBeenCalledWith 'root/config/ftoggle.banana.json', JSON.stringify(version: 1), jasmine.any(Function)
    And -> expect(@cb).toHaveBeenCalledWith undefined, 'feature', 'traffic', 'banana'

  describe '.stage', ->
    Given -> spyOn(@subject, 'fromRoot').andCallFake (p) -> "root/#{p}"
    Given -> @add = new EventEmitter()
    Given -> @cb = jasmine.createSpy 'cb'
    Given -> @options =
      configDir: 'config'

    context 'no error - all configs', ->
      Given -> @cp.spawn.when('git', ['add', 'root/config/*']).thenReturn @add
      When -> @subject.stage.apply @options, ['feature', 'traffic', @cb]
      And -> @add.emit 'close', 0
      Then -> expect(@cb).toHaveBeenCalledWith null, 'feature', 'traffic'

    context 'no error - list of configs', ->
      Given -> @options.stage = ['banana', 'pear']
      Given -> @cp.spawn.when('git', ['add', 'root/config/ftoggle.banana.json', 'root/config/ftoggle.pear.json']).thenReturn @add
      When -> @subject.stage.apply @options, ['feature', 'traffic', @cb]
      And -> @add.emit 'close', 0
      Then -> expect(@cb).toHaveBeenCalledWith null, 'feature', 'traffic'

    context 'error - list of configs', ->
      Given -> @options.stage = ['banana', 'pear']
      Given -> @cp.spawn.when('git', ['add', 'root/config/ftoggle.banana.json', 'root/config/ftoggle.pear.json']).thenReturn @add
      When -> @subject.stage.apply @options, ['feature', 'traffic', @cb]
      And -> @add.emit 'close', 1
      Then -> expect(@cb).toHaveBeenCalledWith "#{chalk.gray('git add root/config/ftoggle.banana.json root/config/ftoggle.pear.json')} returned code #{chalk.red('1')}", 'feature', 'traffic'

    context 'error - all configs', ->
      Given -> @cp.spawn.when('git', ['add', 'root/config/*']).thenReturn @add
      When -> @subject.stage.apply @options, ['feature', 'traffic', @cb]
      And -> @add.emit 'close', 1
      Then -> expect(@cb).toHaveBeenCalledWith "#{chalk.gray('git add root/config/*')} returned code #{chalk.red('1')}", 'feature', 'traffic'

  describe '.commit', ->
    Given -> @commit = new EventEmitter
    Given -> @cp.spawn.when('git', ['commit', '-m', 'Added ftoggle feature foo.bar to banana and pear']).thenReturn @commit
    Given -> @cb = jasmine.createSpy 'cb'
    Given -> @options =
      commitMsg: 'Added ftoggle feature foo.bar to banana and pear'

    context 'no error', ->
      When -> @subject.commit.apply @options, ['feature', 'traffic', @cb]
      And -> @commit.emit 'close', 0
      Then -> expect(@cb).toHaveBeenCalledWith null, 'feature', 'traffic'

    context 'error', ->
      When -> @subject.commit.apply @options, ['feature', 'traffic', @cb]
      And -> @commit.emit 'close', 1
      Then -> expect(@cb).toHaveBeenCalledWith "#{chalk.gray('git commit -m \'Added ftoggle feature foo.bar to banana and pear\'')} returned code #{chalk.red('1')}", 'feature', 'traffic'
