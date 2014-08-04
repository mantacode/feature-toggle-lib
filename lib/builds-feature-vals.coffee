_ = require('underscore')

# userConfig like:
#   enabled: true
#   foo:
#     enabled: true
#     baz:
#       enabled: false
#   bar:
#     enabled: false


module.exports = class BuildsFeatureVals
    constructor: ->
      @specialKeys = ["config", "enabled"]

    build: (userConfig, toggleConfig) ->
      _({}).tap (here) =>
        return if userConfig.enabled != true
        here = _(here).extend @confFor(toggleConfig)
        _(userConfig).chain().omit(@specialKeys).each (v, k) =>
          here = _(here).extend @build(v, toggleConfig["features"][k])

    #private

    confFor: (toggleConfig) ->
      if toggleConfig.conf? then toggleConfig.conf else {}

