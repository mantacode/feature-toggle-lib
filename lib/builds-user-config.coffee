_ = require('underscore')

module.exports = class BuildsUserConfig

  constructor: (@math) ->

  build: (config, cookie = {}, pass = false) ->
    _({}).tap (userConfig) =>
      alreadySet = cookie.enabled? and not config.unsticky
      if alreadySet
        userConfig.enabled = cookie.enabled
      else
        userConfig.enabled = (if config.traffic? then @math.random() <= config.traffic else true)
        userConfig.enabled = true if pass

      userConfig.version = config.version if config.version?
      if config.features? and userConfig.enabled
        if config.exclusiveSplit
          if not alreadySet
            # need to pick the exclusive split winner
            pick = @exclusiveSplit(config.features, cookie, config.unsticky)
            if pick
              userConfig[pick] = @build(config.features[pick], cookie[pick], true)
          else
            # we already picked a winner, loop through features to find only that one and (re)build it
            _(@validSplitKeys(cookie)).each (name) =>
              if (cookie[name].enabled)
                userConfig[name] = @build(config.features[name], cookie[name])
        else
          _(config.features).each (feature, name) =>
            userConfig[name] = @build(feature, cookie[name])

  # private

  exclusiveSplit: (features, cookie, unsticky) ->
    if not unsticky and @validSplitKeys(cookie).length > 0
      return @validSplitKeys(cookie)[0]

    floor = 0
    winner = null
    r = @math.random()
    _(features).each (feature, name) ->
      if feature.traffic?
        ceiling = floor + feature.traffic
        winner = name if floor <= r && ceiling > r
        floor = ceiling
    return winner


  validSplitKeys: (base) ->
    return [] if not base
    return _(_(base).keys()).without("version", "enabled")
