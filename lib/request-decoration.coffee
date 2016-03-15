_ = if (typeof window isnt 'undefined' and window._) then window._ else require('lodash')

module.exports = class RequestDecoration
  constructor: (@config, @cookie, @featureVals = {}, @toggleConfig = {}) ->

  isFeatureEnabled: (feature, trueCallback, falseCallback) ->
    _.has @config, feature

  findEnabledChildren: (prefix) ->
    _(_.get(@config, prefix)).keys().without('e').value()

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
          @del @config, current

        _.set(@config, current + '.e', 1)

      @cookie(@toggleName(), JSON.stringify(@config), @toggleConfig.cookieOptions)
    this

  disable: (feature) ->
    if _.has @toggleConfig, @makeFeaturePath(feature)
      @del @config, feature
      @cookie(@toggleName(), JSON.stringify(@config), @toggleConfig.cookieOptions)
    this

  #private
  
  toggleName: -> "ftoggle-#{@toggleConfig.name}"

  makeFeaturePath: (feature) -> 'features.' + feature.split('.').join('.features.')

  del: (obj, prop) ->
    if prop.indexOf('.') == -1
      delete obj[ prop ]
    else
      parts = prop.split('.')
      subpath = parts.slice(0, -1).join('.')
      subobj = _.get obj, subpath
      if _.isPlainObject(subobj)
        delete subobj[ parts[parts.length - 1] ]
    return obj
