_ = require('underscore')

module.exports = class BuildsUserConfig

  constructor: (@math) ->

  build: (config, cookie = {}, pass = false, bot = false) ->
    _({}).tap (userConfig) =>
      if config?
        alreadySet = cookie.enabled? and not config.unsticky
        if alreadySet
          userConfig.enabled = cookie.enabled
        else
          traffic = @traffic(config, bot)
          userConfig.enabled = (if traffic? then @math.random() <= traffic else true)
          userConfig.enabled = true if pass

        userConfig.version = config.version if config.version?
        if config.features? and userConfig.enabled
          if config.exclusiveSplit
            if not alreadySet
              # need to pick the exclusive split winner
              pick = @exclusiveSplit(config.features, cookie, config.unsticky, bot)
              if pick
                userConfig[pick] = @build(config.features[pick], cookie[pick], true, bot)
            else
              # we already picked a winner, loop through features to find only that one and (re)build it
              rebuilt = false
              _(@validSplitKeys(cookie)).each (name) =>
                if (cookie[name].enabled and config.features[name]?)
                  rebuilt = true
                  userConfig[name] = @build(config.features[name], cookie[name], false, bot)

              if (!rebuilt)
                # cookie did not have a valid winner set, so re-pick the winner
                pick = @exclusiveSplit(config.features, cookie, config.unsticky, bot)
                if pick
                  userConfig[pick] = @build(config.features[pick], cookie[pick], true, bot)
          else
            _(config.features).each (feature, name) =>
              userConfig[name] = @build(feature, cookie[name], false, bot)

  # private

  traffic: (config, bot) ->
    if config?
      if config.botTraffic? && bot then config.botTraffic else config.traffic
    else
      null

  exclusiveSplit: (features, cookie, unsticky, bot) ->
    if not unsticky and @validSplitKeys(cookie).length > 0
      cookieWinner = @validSplitKeys(cookie)[0]
      # make sure the value from the cookie exists in the config
      if features[cookieWinner]?
        return @validSplitKeys(cookie)[0]

    floor = 0
    winner = null
    r = @math.random()
    _(features).each (feature, name) =>
      traffic = @traffic(feature, bot)
      if traffic?
        ceiling = floor + traffic
        winner = name if floor <= r && ceiling > r
        floor = ceiling
    return winner


  validSplitKeys: (base) ->
    return [] if not base
    return _(_(base).keys()).without("version", "enabled")
