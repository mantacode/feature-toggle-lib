program = require 'commander'
utils = require './utils'
coerce = require './coerce'
actions = require './actions'
_ = require 'underscore'

program.usage('<command> [feature] [options]')

try
  config = require("#{utils.getFtoggleDir()}/.ftoggle.config")
catch

if !config && !~process.argv.join(' ').indexOf 'ftoggle init'
  utils.writeBlock 'Unable to locate configuration information about this repository.', 'If you have not done so, you can run ' + 'ftoggle init'.grey + ' to configure ftoggle for this repository.'
  return process.exit()

if config
  confWithVersion = _(config.environments).find (env) ->
    try
      require(config[env])
      return true
    catch
      return false

  version = require(config[confWithVersion] || '../package').version
else
  version = require('../package').version

program.version(version)

program.name = 'ftoggle'

###
#  Tell ftoggle about where things are
###
program
  .command('init [name]')
  .option('-e, --env <name>', 'Specify environments', coerce.collect, [])
  .option('-c, --config-dir <path>', 'Location of config files relative to cwd')
  .option('-n, --name <name>', 'Project name')
  .action(actions.init)

program.parse process.argv

module.exports = program
