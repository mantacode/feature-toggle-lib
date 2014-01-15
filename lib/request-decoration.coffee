_ = require('underscore')

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
    children = _.filter Object.keys(feature), (k) ->
      feature[k].enabled == true
    if children? then children else []

  #private

  lookupFeature: (path, nodes) ->
    current = path.shift()
    if current? && nodes?
        @lookupFeature(path, nodes[current])
    else
      nodes

  lookuppFeature: (path, nodes) ->
    parent = path.shift()
    return false unless nodes[parent]?.enabled
    return true unless path.length > 0
    @lookupFeature(path, nodes[parent])
