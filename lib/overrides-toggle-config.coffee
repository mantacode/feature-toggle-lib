module.exports = class OverridesToggleConfig
  constructor: (@config) ->

  override: (overrides, enable) ->
    return this unless overrides?
    @applyToggles(overrides.split(","), @config, enable)
    this

  #private
  applyToggles: (parts, data, val) ->
    thisPart = parts.shift()
    if data[thisPart]
      if parts.length < 1
        data[thisPart].enabled = val
      else
        @applyToggles(parts, data[thisPart], val)
