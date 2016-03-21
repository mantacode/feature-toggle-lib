_ = if (typeof window isnt 'undefined' and window._) then window._ else require('lodash')

module.exports = class RequestDecoration
  constructor: (@config, @featureVals = {}, @toggleConfig = {}) ->

  isFeatureEnabled: (feature, trueCallback, falseCallback) ->
    return Boolean(_.get(@config, feature + '.e'))

  findEnabledChildren: (prefix) ->
    subset = if prefix then _.get(@config, prefix) else @config
    return _(subset).keys().without('e', 'v').value()

  doesFeatureExist: (feature) ->
    _.has @toggleConfig, @makeFeaturePath(feature)

  getFeatures: () ->
    @config

  featureVal: (key) ->
    @featureVals[key] or null

  getFeatureVals: () ->
    @featureVals

  setFeatures: (ftr) ->
    featureConf = _.get @toggleConfig, ftr + '.conf'
    _.each featureConf, (v, k) =>
      @featureVals[k] = v
    this

  unsetFeatures: (ftr) ->
    featureConf = _.get @toggleConfig, ftr + '.conf'
    _.each featureConf, (v, k) =>
      delete @featureVals[k]
    this

  enable: (feature) ->
    featurePath = @makeFeaturePath(feature)
    if _.has @toggleConfig, featurePath
      parts = feature.split('.')
      current = ''
      while parts.length > 0
        current += (if current then '.' else '') + parts.shift()
        innerFeaturePath = @makeFeaturePath(current)

        currentConfig = _.get(@toggleConfig, innerFeaturePath)
        if currentConfig?.exclusiveSplit
          _.unset @config, current
          _.each currentConfig.features, (v, k) =>
            @unsetFeatures(innerFeaturePath + '.features.' + k)

        _.set(@config, current + '.e', 1)
        @setFeatures(innerFeaturePath)
    this

  disable: (feature) ->
    featurePath = @makeFeaturePath(feature)
    if _.has @toggleConfig, featurePath
      _.unset @config, feature
      @unsetFeatures(featurePath)
      _.each @getAllChildNodes(@toggleConfig, featurePath), (node) =>
        @unsetFeatures(node)
    this

  #private
  
  toggleName: -> "ftoggle-#{@toggleConfig.name}"

  makeFeaturePath: (feature) -> 'features.' + feature.split('.').join('.features.')

  getAllChildNodes: (config, path) ->
    thisConfig = _.get(config, path + '.features')
    return _.reduce(thisConfig, (memo, v, k) =>
      inner = path + '.features.' + k
      memo.push(inner)
      _.each @getAllChildNodes(thisConfig, k), (child) ->
        memo.push(path + '.features.' + child)
      return memo
    , [])
