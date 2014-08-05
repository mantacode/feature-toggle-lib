_ = require 'underscore'
cp = require 'child_process'
chalk = require 'chalk'

describe 'cli main', ->
  context 'with no config', ->
    Given -> spyOn process, 'exit'
    Given -> @utils = jasmine.createSpyObj 'utils', ['writeBlock']
    When -> @subject = requireSubject 'cli/main',
      './utils': @utils
    Then -> expect(@utils.writeBlock).toHaveBeenCalledWith 'Unable to locate configuration information about this repository.', "If you have not done so, you can run #{chalk.gray('ftoggle init')} to configure ftoggle for this repository."
    And -> expect(process.exit).toHaveBeenCalled()

  context 'with config', ->
    Given -> spyOn process, 'exit'
    Given -> @utils = jasmine.createSpyObj 'utils', ['writeBlock', 'exit', 'getFtoggleDir', 'getConfigs', 'write', 'bump', 'stage', 'commit']
    Given -> @utils.getFtoggleDir.andReturn '..'
    Given -> @config =
      environments: ['production']
      configDir: 'config'
      production:
        path: 'ftoggle.json'
    Given -> @actions = jasmine.createSpyObj 'actions', ['init', 'add']
    Given -> @subject = requireSubject 'cli/main',
      './utils': @utils
      './actions': @actions
      '../.ftoggle.config': @config
      'ftoggle.json': { version: 1 }

    describe 'name', ->
      Then -> expect(@subject.name).toBe 'ftoggle'

    describe 'version', ->
      Then -> expect(@subject.version()).toBe 1

    describe '.takeAction', ->
      Given -> @utils.commit.andCallFake (cb) ->
        @check += 'commit'
        cb()
      Given -> @utils.stage.andCallFake (cb) ->
        @check += 'stage'
        cb()
      Given -> @utils.write.andCallFake (cb) ->
        @check += 'write'
        cb()
      Given -> @utils.bump.andCallFake (cb) ->
        @check += 'bump'
        cb()
      Given -> @actions.add.andCallFake (cb) ->
        @check += 'add'
        cb()
      Given -> @options =
        _name: 'add'
        check: ''
      context 'base options', ->
        Given -> @options =
          _name: 'add'
          check: ''
        When -> @subject.takeAction @options
        Then -> expect(@options.ftoggle).toEqual
          environments: ['production']
          configDir: 'config'
          production:
            path: 'ftoggle.json'
            config:
              version: 1
        And -> expect(@options.modified).toEqual []
        And -> expect(@utils.exit).toHaveBeenCalled()
        And -> expect(@options.check).toBe 'addwrite'

      context 'with all options', ->
        Given -> @options =
          _name: 'add'
          check: ''
          bump: true
          stage: true
          commit: true
        When -> @subject.takeAction @options
        Then -> expect(@options.ftoggle).toEqual
          environments: ['production']
          configDir: 'config'
          production:
            path: 'ftoggle.json'
            config:
              version: 1
        And -> expect(@options.modified).toEqual []
        And -> expect(@utils.exit).toHaveBeenCalled()
        And -> expect(@options.check).toBe 'addbumpwritestagecommit'

      context 'with commit and not add', ->
        Given -> @options =
          _name: 'add'
          check: ''
          commit: true
        When -> @subject.takeAction @options
        Then -> expect(@options.ftoggle).toEqual
          environments: ['production']
          configDir: 'config'
          production:
            path: 'ftoggle.json'
            config:
              version: 1
        And -> expect(@options.modified).toEqual []
        And -> expect(@utils.exit).toHaveBeenCalled()
        And -> expect(@options.stage).toBe true
        And -> expect(@options.check).toBe 'addwritestagecommit'

    describe 'init', ->
      context 'correct options', ->
        Given -> @cmd = _(@subject.commands).findWhere { _name: 'init' }
        Then -> expect(_(@cmd.options).pluck('flags').join('\n')).toBe """
          -e, --env <name|list>
          -c, --config-dir <path>
          -n, --name <name>
        """
        And -> expect(_(@cmd.options).pluck('description').join('\n')).toBe """
          Specify environments
          Location of config files relative to cwd
          Project name
        """
        And -> expect(@cmd._args).toEqual [
          required: false
          name: 'name'
        ]
        And -> expect(@cmd._description).toBe 'Initialize ftoggle in a project'

      context 'calls correct action', ->
        When -> @subject.parse(['node', 'ftoggle', 'init'])
        Then -> expect(@actions.init).toHaveBeenCalled()

    describe 'add', ->
      context 'correct options', ->
        Given -> @cmd = _(@subject.commands).findWhere { _name: 'add' }
        Then -> expect(_(@cmd.options).pluck('flags').join('\n')).toBe """
          -s, --stage [env|list]
          -b, --bump
          -c, --commit [env|list]
          -e, --env <name|list>
          --dry-run
          -E, --enable [name|list]
          -s, --split-plan <name>
        """
        And -> expect(_(@cmd.options).pluck('description').join('\n')).toBe """
          Stage the changes [for a given env only]
          Bump the version
          Commit the changes [for a given env only]
          List of environments to apply the change to
          Write changes to console instead of the config files
          Set traffic to 1 in these configs
          Method for handling exclusive splits in feature path (one of on, off, split, or prompt)
        """
        And -> expect(@cmd._args).toEqual [
          required: true
          name: 'feature'
        ]
        And -> expect(@cmd._description).toBe 'Add a new feature to ftoggle'

      context 'calls correct action', ->
        Given -> spyOn @subject._events, 'add'
        When -> @subject.parse(['node', 'ftoggle', 'add', 'feature'])
        Then -> expect(@subject._events.add).toHaveBeenCalled()
