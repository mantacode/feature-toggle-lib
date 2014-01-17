module.exports = class OverridesToggleConfig
  constructor: (@config, @userConfig) ->

  override: (overrides, enable) ->
    return this unless overrides?
    console.log "GO\n\n"
    overrides.split(",").forEach (v) =>
      @applyToggles(v.split("."), @userConfig, enable)
    this

  #private
  applyToggles: (parts, data, val) ->
    console.log "before", data
    thisPart = parts.shift()
    unless data[thisPart]?
      data[thisPart] = { enabled: val }
    data[thisPart].enabled = val
    Object.keys(data).forEach (k) ->
      if typeof data[k] == 'object' && data[k].enabled?
        data[k].enabled = !val unless k == thisPart
    if parts.length > 0 
      @applyToggles(parts, data[thisPart], val)
    console.log "after ", data
