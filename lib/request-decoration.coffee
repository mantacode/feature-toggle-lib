module.exports = class RequestDecoration
  constructor: (@config) ->

  isFeatureEnabled: (feature, trueCallback, falseCallback) ->
    featureNodes = @lookupFeature(feature.split("."), @config)
    if enabled = featureNodes? && featureNodes.enabled
      trueCallback?(feature)
    else
      falseCallback?(feature)
    enabled

  findEnabledChildren: (prefix) ->
    p = []
    p = prefix.split(".") if prefix?
    feature = @lookupFeature(p, @config)
    return [] unless feature
    children = @filter Object.keys(feature), (k) ->
      feature[k].enabled == true
    if children? then children else []

  getFeatures: () ->
    @config

  #private

  lookupFeature: (path, nodes) ->
    current = path.shift()
    if current? && nodes?
        @lookupFeature(path, nodes[current])
    else
      nodes

  # not using underscore here, for front-end reasons
  filter: (list, f) ->
    out = []
    list.forEach (e) ->
      if f(e)
        out.push e
    return out
