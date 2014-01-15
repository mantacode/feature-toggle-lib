_ = require('underscore')

module.exports = class BuildsUserConfig

  constructor: (@math) ->

  build: (config, pass = false) ->
    _({}).tap (userConfig) =>
      userConfig.enabled = (if config.traffic? then @math.random() <= config.traffic else true)
      userConfig.enabled = true if pass
      userConfig.version = config.version if config.version?
      if userConfig.enabled && config.features?
        if config.exclusiveSplit
          pick = @exclusiveSplit(config.features)
          userConfig[pick] = @build(config.features[pick], true)
        else
          _(config.features).each (feature, name) =>
            userConfig[name] = @build(feature)

  # private
  
  exclusiveSplit: (features) ->
    floor = 0
    winner = null
    r = @math.random()
    _(features).each (feature, name) ->
      ceiling = floor + feature.traffic
      winner = name if floor <= r && ceiling > r
      floor = ceiling
    return winner

