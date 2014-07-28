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
    Given -> @utils = jasmine.createSpyObj 'utils', ['writeLines']
    Given -> @config =
      environments: ['production']
      production: 'ftoggle.json'
    Given -> @actions = jasmine.createSpyObj 'actions', ['init']
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
          -e, --env <name>
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

      context 'calls correct action', ->
        When -> @subject.parse(['node', 'ftoggle', 'init'])
        Then -> expect(@actions.init).toHaveBeenCalled()
