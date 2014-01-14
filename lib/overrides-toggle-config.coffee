module.exports = class OverridesToggleConfig
  constructor: (@config) ->

  override: (overrides, enable) ->
    return this unless overrides?
    overrides.split(",").forEach (v) =>
      @applyToggles(v.split("."), @config, enable)
    this

  #private
  applyToggles: (parts, data, val) ->
    thisPart = parts.shift()
    unless data[thisPart]?
      data[thisPart] = { enabled: val }
    data[thisPart].enabled = val
    if parts.length > 0 
      @applyToggles(parts, data[thisPart], val)
