module.exports = class RequestDecoration
  constructor: (@config, @featureVals) ->

  isFeatureEnabled: (feature, trueCallback, falseCallback) ->
    featureNodes = @lookupFeature(feature.split("."), @objClone(@config))
    if enabled = (featureNodes? && featureNodes.enabled)
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

  doesFeatureExist: (feature) ->
    nodes = @lookupFeature(feature.split("."), @config)
    return nodes?

  getFeatures: () ->
    @config


  featureVal: (key) ->
    if @featureVals[key]? then @featureVals[key] else null

  getFeatureVals: () ->
    @featureVals

  #private

  lookupFeature: (path, nodes, over = null) ->
    current = path.shift()
    nodes.enabled = over if over?
    if current? && nodes?
      over = false if nodes.enabled? && nodes.enabled == false
      @lookupFeature(path, nodes[current], over)
    else
      nodes

  # not using underscore here, for front-end reasons
  filter: (list, f) ->
    out = []
    list.forEach (e) ->
      if f(e)
        out.push e
    return out

  # same story; limiting dependencies
  objClone: (o) ->
    if typeof o == 'object'
      out = {}
      out[k] = @objClone(v) for k, v of o
      return out
    else
      return o
