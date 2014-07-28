_ = require('underscore')

module.exports = class BuildsUserConfig

  constructor: (@math) ->

  build: (config, base = {}, pass = false) ->
    _({}).tap (userConfig) =>
      if base.enabled? and not config.unsticky
        userConfig.enabled = base.enabled
      else
        userConfig.enabled = (if config.traffic? then @math.random() <= config.traffic else true)
        userConfig.enabled = true if pass
      userConfig.version = config.version if config.version?
      if config.features?
        if config.exclusiveSplit
          pick = @exclusiveSplit(config.features, base, config.unsticky)
          userConfig[pick] = @build(config.features[pick], base[pick], true)
        else
          _(config.features).each (feature, name) =>
            userConfig[name] = @build(feature, base[name])

  # private
  
  exclusiveSplit: (features, base, unsticky) ->
    if not unsticky and @validSplitKeys(base).length > 0
      return @validSplitKeys(base)[0]

    floor = 0
    winner = null
    r = @math.random()
    _(features).each (feature, name) ->
      ceiling = floor + feature.traffic
      winner = name if floor <= r && ceiling > r
      floor = ceiling
    return winner

  validSplitKeys: (keys) ->
    return [] if not keys
    return _(_(keys).keys()).without("version", "enabled")
