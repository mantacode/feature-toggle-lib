async = require 'async'
fs = require 'fs'
path = require 'path'
utils = require './utils'
_ = require 'underscore'

exports.init = (name, options) ->
  root = utils.getRoot()
  options.env = if options.env.length then options.env else [ 'production', 'development' ]
  options.name = name || options.name || path.basename(root)
  options.configDir = options.configDir || 'config'
  ftoggleDir = "#{root}/node_modules/feature-toggle-lib"
  async.parallel [
    (next) ->
      config = _(options.env).reduce (memo, env) ->
        console.log arguments
        memo[env] = path.relative ftoggleDir, "#{root}/#{options.configDir}/ftoggle.' + env + '.json'
        return memo
      , { environments: options.env }
      console.log config
      fs.writeFile("#{ftoggleDir/.ftoggle.config.json", JSON.stringify(config, null, 2), next)
  ], (err) ->
    utils.exit(err)
