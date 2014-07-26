program = require 'commander'
utils = require './utils'
config

try
  config = require '../.ftoggle.config'
catch
  utils.writeLines 'Unable to locate configuration information about this repository.', 'If you have not done so, you can run ' + 'ftoggle init'.grey + ' to configure ftoggle for this repository.'
  process.exit()

