module.exports = class OverridesToggleConfig
  constructor: (@config, @userConfig) ->

  override: (overrides, enable) ->
    return this unless overrides?
    overrides.split(",").forEach (v) =>
      if (@doesFeatureExist(v, @config))
        @applyToggles(v.split("."), @config, @userConfig, enable)
    return this

  #private
  applyToggles: (parts, config, data, val) ->
    thisPart = parts.shift()
    unless data[thisPart]?
      data[thisPart] = { enabled: val }
    data[thisPart].e = val
    if config.exclusiveSplit
      Object.keys(data).forEach (k) ->
        if typeof data[k] == 'object' && data[k].e?
          data[k].e = !val unless k == thisPart
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
        return true
    else
      return false
