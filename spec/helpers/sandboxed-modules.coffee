SandboxedModule = require('sandboxed-module')

global.requireSubject = (path, requires, globals) ->
  SandboxedModule.require("./../../#{path}",  {requires}, {globals})
