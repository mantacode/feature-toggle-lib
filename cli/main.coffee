program = require 'commander'
utils = require './utils'
coerce = require './coerce'
actions = require './actions'
_ = require 'underscore'

#  Add some shortcuts to the options that every command has
program.Command.prototype.add = ->
  @option('-a, --add', 'Stage the changes')

program.Command.prototype.bump = ->
  @option('-b, --bump', 'Bump the version')

program.Command.prototype.commit = ->
  @option('-c, --commit', 'Commit the changes')

program.Command.prototype.envs = ->
  @option('-e, --env <name>|<list>', 'List of environments to apply the change to', coerce.collect, [])

program.Command.prototype.common = ->
  @add().bump().commit().envs()

program.usage('<command> [feature] [options]')

#  Try to get the ftoggle config
try
  config = require("#{utils.getFtoggleDir()}/.ftoggle.config")
catch

#  Don't try to do everything else unless we have a config or we're initializing
if !config && !~process.argv.join(' ').indexOf 'ftoggle init'
  utils.writeBlock 'Unable to locate configuration information about this repository.', 'If you have not done so, you can run ' + 'ftoggle init'.grey + ' to configure ftoggle for this repository.'
  return process.exit()

version = null

#  Get the config for each environment
if config
  _(config.environments).each (env) ->
    config[env].config = require config[env].path
    version = version || config[env].config.version

program.version(version || require('../package').version)

program.name = 'ftoggle'

takeAction = (args...) ->
  options = args.pop()
  options.ftoggle = config
  actions[options._name].apply(actions, arguments)

#  Tell ftoggle about where things are
program
  .command('init [name]')
  .description('Initialize ftoggle in a project')
  .option('-e, --env <name>|<list>', 'Specify environments', coerce.collect, [])
  .option('-c, --config-dir <path>', 'Location of config files relative to cwd')
  .option('-n, --name <name>', 'Project name')
  .action(actions.init)

#  Add a new feature to ftoggle
program
  .command('add <feature>')
  .description('Add a new feature to ftoggle')
  .common()
  .option('-o, --off <name>|<list>', 'Set traffic to 0 in these configs', coerce.collect, [])
  .action(takeAction)

program.parse process.argv

module.exports = program
