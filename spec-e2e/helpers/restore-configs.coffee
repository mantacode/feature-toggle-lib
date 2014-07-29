fs = require 'fs'

# Require is relative to the current file
foo = require '../cli/ftoggle.foo'
bar = require '../cli/ftoggle.bar'

# fs is relative to cwd
afterEach -> fs.writeFileSync './spec-e2e/cli/ftoggle.foo.json', JSON.stringify(foo, null, 2)
afterEach -> fs.writeFileSync './spec-e2e/cli/ftoggle.bar.json', JSON.stringify(bar, null, 2)
