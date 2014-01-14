_ = require('underscore')

module.exports = class BuildsUserConfig

  constructor: (@math) ->

  build: (config) ->
    _({}).tap (userConfig) =>
      userConfig.enabled = (if config.traffic? then @math.random() <= config.traffic else true)
      userConfig.version = config.version if config.version?
      if userConfig.enabled && config.features?
        _(config.features).each (feature, name) =>
          userConfig[name] = @build(feature)
