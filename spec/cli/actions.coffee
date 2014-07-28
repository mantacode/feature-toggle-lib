path = require 'path'

describe.only 'actions', ->
  Given -> @fs = jasmine.createSpyObj 'fs', ['exists', 'writeFile']
  Given -> @utils = jasmine.createSpyObj 'utils', ['getRoot', 'exit']
  Given -> @subject = requireSubject 'cli/actions',
    fs: @fs
    './utils': @utils

  describe '.init', ->
    Given -> @cb = jasmine.captor()
    Given -> @utils.getRoot.andReturn 'banana'
    Given -> @fs.writeFile.andCallFake (path, content, cb) -> cb()
    Given -> @options =
      env: [ 'foo', 'bar', 'baz' ]
      configDir: './config'
      name: 'banana'
    When -> @subject.init 'undefined', @options
    Then -> expect(@fs.writeFile).toHaveBeenCalledWith 'banana/node_modules/feature-toggle-lib/.ftoggle.config.json', JSON.stringify(
      environments: ['foo', 'bar', 'baz']
      foo: './../../../config/ftoggle.foo.json'
      bar: './../../../config/ftoggle.bar.json'
      baz: './../../../config/ftoggle.baz.json'
    , null, 2), jasmine.any(Function)
    And -> expect(@utils.exit).toHaveBeenCalled()
