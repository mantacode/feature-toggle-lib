async = require 'async'
fs = require 'fs'
path = require 'path'
utils = require './utils'

exports.init = (name, options) ->
  root = utils.getRoot()
  name = name || options.name || path.basename(root)
  options.env = if options.env.length then options.env else [ 'production', 'development' ]
  options.configDir = options.configDir || "./config"
  async.each options.env, (env, next) ->
    fs.writeFile "#{root}/#{options.configDir}/ftoggle.#{env}.json", JSON.stringify(
      version: 1
      name: "#{name}-#{env}"
      features: {}
    , null, 2), next
  , (err) ->
    if err
      utils.exit(err)
    else
      fs.writeFile "#{root}/node_modules/ftoggle/.ftoggle.config.json", JSON.stringify(
        environments: options.env
        configDir: options.configDir
        name: name
      , null, 2), utils.exit

exports.add = (feature, env, cb) ->
  if @ftoggle[env]
    traffic = if @enable == true or (@enable? and env in @enable) then 1 else 0
    utils.expand(@ftoggle[env].features, feature, { traffic: traffic }, @splitPlan)
    @modified.push(env)
  cb(null, feature, env)
