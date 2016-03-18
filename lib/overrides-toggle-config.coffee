_ = if (typeof window isnt 'undefined' and window._) then window._ else require('lodash')

module.exports = class OverridesToggleConfig
  constructor: (@config, @userConfig) ->

  override: (overrides, enable) ->
    return this unless overrides?
    overrides.split(",").forEach (v) =>
      if (@doesFeatureExist(v, @config))
        if enable
          @applyToggles(v.split("."), @config, @userConfig, 1)
        else
          _.unset @userConfig, v
    return this

  #private
  applyToggles: (parts, config, data, val) ->
    thisPart = parts.shift()
    if config.exclusiveSplit
      Object.keys(data).forEach (k) ->
        if k != 'e'
          delete data[k]

    data[thisPart] = data[thisPart] or {}
    data[thisPart].e = 1

    if parts.length > 0
      @applyToggles(parts, config.features[thisPart], data[thisPart], val)

  doesFeatureExist: (feature, @config) ->
    return @lookupFeature(feature.split("."), @config)


  lookupFeature: (path, nodes, enabledOverride = null) ->
    current = path.shift()
    if nodes.features[current]?
      if path.length > 0
        @lookupFeature(path, nodes.features[current], enabledOverride)
      else
        return 1
    else
      return 0
