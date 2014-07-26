describe 'cli main', ->
  context 'with no config', ->
    Given -> spyOn process, 'exit'
    Given -> @utils = jasmine.createSpyObj 'utils', ['writeLines']
    When -> @subject = requireSubject 'cli/main',
      './utils': @utils
    Then -> expect(@utils.writeLines).toHaveBeenCalledWith 'Unable to locate configuration information about this repository.', 'If you have not done so, you can run ' + 'ftoggle init'.grey + ' to configure ftoggle for this repository.'
    And -> expect(process.exit).toHaveBeenCalled()
