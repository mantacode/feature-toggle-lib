_ = require('lodash')

# userConfig like:
#   e: 1
#   foo:
#     e: 1


module.exports = class BuildsFeatureVals
    constructor: ->
      @specialKeys = ["config", "e"]

    build: (userConfig, toggleConfig) ->
      _.tap {}, (here) =>
        return if userConfig.e != 1
        here = _.extend here, @confFor(toggleConfig)
        _(userConfig).omit(@specialKeys).each (v, k) =>
          here = _.extend here, @build(v, toggleConfig["features"][k])

    #private

    confFor: (toggleConfig) ->
      if toggleConfig?.conf? then toggleConfig.conf else {}

