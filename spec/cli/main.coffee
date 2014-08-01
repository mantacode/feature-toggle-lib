_ = require 'underscore'
cp = require 'child_process'

describe 'cli main', ->
  context 'with no config', ->
    Given -> spyOn process, 'exit'
    Given -> @utils = jasmine.createSpyObj 'utils', ['writeBlock']
    When -> @subject = requireSubject 'cli/main',
      './utils': @utils
    # Can't seem to get "colors" working from the test (hence the random "undefined")
    Then -> expect(@utils.writeBlock).toHaveBeenCalledWith 'Unable to locate configuration information about this repository.', 'If you have not done so, you can run undefined to configure ftoggle for this repository.'
    And -> expect(process.exit).toHaveBeenCalled()

  context 'with config', ->
    Given -> spyOn process, 'exit'
    Given -> @utils = jasmine.createSpyObj 'utils', ['writeBlock', 'getFtoggleDir', 'getConfigs']
    Given -> @utils.getFtoggleDir.andReturn '..'
    Given -> @config =
      environments: ['production']
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

    describe 'init', ->
      context 'correct options', ->
        Given -> @cmd = _(@subject.commands).findWhere { _name: 'init' }
        Then -> expect(_(@cmd.options).pluck('flags').join('\n')).toBe """
          -e, --env <name>|<list>
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
          -a, --add
          -b, --bump
          -c, --commit
          -e, --env <name>|<list>
          -o, --off <name>|<list>
        """
        And -> expect(_(@cmd.options).pluck('description').join('\n')).toBe """
          Stage the changes
          Bump the version
          Commit the changes
          List of environments to apply the change to
          Set traffic to 0 in these configs
        """
        And -> expect(@cmd._args).toEqual [
          required: true
          name: 'feature'
        ]
        And -> expect(@cmd._description).toBe 'Add a new feature to ftoggle'

      context 'calls correct action', ->
        When -> @subject.parse(['node', 'ftoggle', 'add', 'feature'])
        Then -> expect(@actions.add).toHaveBeenCalled()