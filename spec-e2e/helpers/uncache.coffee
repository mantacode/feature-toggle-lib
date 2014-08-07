path = require 'path'

# Multiple tests in the same file are problem because node caches the results of require
afterEach -> delete require.cache[path.resolve(__dirname, '../cli/ftoggle.foo.json')]
afterEach -> delete require.cache[path.resolve(__dirname, '../cli/ftoggle.bar.json')]
