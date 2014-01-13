_ = require('underscore')

module.exports = class BuildsUserConfig

  constructor: (@math) ->

  build: (config) ->
    enabled = (if config.traffic? then @math.random() <= config.traffic else true)
    version = config.version if config.version?

    _({enabled, version}).tap (userConfig) =>
      if userConfig.enabled && config.features?
        _(config.features).each (feature, name) =>
          userConfig[name] = @build(feature)
