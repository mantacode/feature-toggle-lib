async = require 'async'
fs = require 'fs'
path = require 'path'
utils = require './utils'
_ = require 'underscore'
list = require 'listify'

exports.init = (name, options) ->
  # Setup
  root = utils.getRoot()
  options.env = if options.env.length then options.env else [ 'production', 'development' ]
  options.name = name || options.name || path.basename(root)
  options.configDir = path.normalize("#{root}/#{(options.configDir || 'config')}")
  ftoggleDir = "#{root}/node_modules/ftoggle"
  
  #Ftoggle config
  config =
    environments: options.env
    configDir: options.configDir
    name: options.name

  # Build an array of functions to pass to async
  funcs = _(options.env).reduce (memo, env) ->
    config[env] =
      path: path.relative(ftoggleDir, "#{options.configDir}/ftoggle.#{env}.json")
    memo.push do (env) ->
      # Environment config
      ftConf =
        version: 1
        name: "#{options.name}-#{env}"
        features: {}
      return (next) ->
        fs.writeFile("#{options.configDir}/ftoggle.#{env}.json", JSON.stringify(ftConf, null, 2), next)
    return memo
  , [
    (next) ->
      fs.writeFile("#{ftoggleDir}/.ftoggle.config.json", JSON.stringify(config, null, 2), next)
  ]

  async.parallel funcs, utils.exit

exports.add = (feature, env, cb) ->
  if @ftoggle[env]
    traffic = if @enable == true or (@enable? and env in @enable) then 1 else 0
    utils.expand(@ftoggle[env].config.features, feature, { traffic: traffic }, @splitPlan)
    @modified.push(env)
  cb(null, feature, env)
