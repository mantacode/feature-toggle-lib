module.exports = class RequestDecoration
  constructor: (@config) ->

  isFeatureEnabled: (feature, trueCallback, falseCallback) ->
    if enabled = @lookupFeature(feature.split("."), @config)
      trueCallback?(feature)
    else
      falseCallback?(feature)
    enabled

  #private

  lookupFeature: (path, nodes) ->
    parent = path.shift()
    return false unless nodes[parent]?.enabled
    return true unless path.length > 0
    @lookupFeature(path, nodes[parent])
