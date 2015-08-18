_ = if (typeof window isnt 'undefined' and window._) then window._ else require('lodash')

module.exports = class RequestDecoration
  constructor: (@config, @featureVals = {}, @toggleConfig = {}) ->

  isFeatureEnabled: (feature, trueCallback, falseCallback) ->
    featureNodes = @lookupFeature(feature.split("."), _.clone(@config))
    if enabled = (featureNodes? && (featureNodes != false) && featureNodes.e)
      trueCallback?(feature)
    else
      falseCallback?(feature)
    Boolean(enabled)

  findEnabledChildren: (prefix) ->
    p = []
    p = prefix.split(".") if prefix?
    feature = @lookupFeature(p, @config)
    return [] unless feature
    children = _.filter(_.keys(feature), (k) ->
      feature[k].e == 1
    )
    if children? then children else []

  doesFeatureExist: (feature) ->
    _.has @toggleConfig, 'features.' + feature.replace('.', '.features.')

  getFeatures: () ->
    @config

  featureVal: (key) ->
    if @featureVals[key]? then @featureVals[key] else null

  getFeatureVals: () ->
    @featureVals

  #private

  lookupFeature: (path, nodes, enabledOverride = null) ->
    current = path.shift()
    nodes.e = enabledOverride if enabledOverride?
    if current? && nodes?
      enabledOverride = false if !nodes.e?
      if enabledOverride? && enabledOverride == false
        return false
      @lookupFeature(path, nodes[current], enabledOverride)
    else
      nodes
