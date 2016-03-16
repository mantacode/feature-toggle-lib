_ = if (typeof window isnt 'undefined' and window._) then window._ else require('lodash')

module.exports = class RequestDecoration
  constructor: (@config, @cookie, @featureVals = {}, @toggleConfig = {}) ->

  isFeatureEnabled: (feature, trueCallback, falseCallback) ->
    return Boolean(_.get(@config, feature + '.e'))

  findEnabledChildren: (prefix) ->
    subset = if prefix then _.get(@config, prefix) else @config
    return _(subset).keys().without('e').value()

  doesFeatureExist: (feature) ->
    _.has @toggleConfig, @makeFeaturePath(feature)

  getFeatures: () ->
    @config

  featureVal: (key) ->
    @featureVals[key] or null

  getFeatureVals: () ->
    @featureVals

  enable: (feature) ->
    if _.has @toggleConfig, @makeFeaturePath(feature)
      parts = feature.split('.')
      current = ''
      while parts.length > 0
        current += (if current then '.' else '') + parts.shift()

        if _.get(@toggleConfig, @makeFeaturePath(current) + '.exclusiveSplit')
          _.unset @config, current

        _.set(@config, current + '.e', 1)

      @cookie(@toggleName(), JSON.stringify(@config), @toggleConfig.cookieOptions)
    this

  disable: (feature) ->
    if _.has @toggleConfig, @makeFeaturePath(feature)
      _.unset @config, feature
      @cookie(@toggleName(), JSON.stringify(@config), @toggleConfig.cookieOptions)
    this

  #private
  
  toggleName: -> "ftoggle-#{@toggleConfig.name}"

  makeFeaturePath: (feature) -> 'features.' + feature.split('.').join('.features.')
