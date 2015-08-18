math = require('./math')
OverridesToggleConfig = require('./overrides-toggle-config')
RequestDecoration = require('./request-decoration')
BuildsUserConfig = require('./builds-user-config')
BuildsFeatureVals = require('./builds-feature-vals')
merger = require('./merger')
_ = require 'lodash'

module.exports = class FeatureToggle

  constructor: ->
    @toggleConfig = {}
    @buildsUserConfig = new BuildsUserConfig(math)
    @buildsFeatureVals = new BuildsFeatureVals()
    @unstickyFeatures = []

  newMiddleware: ->
    (req, res, next) =>
      defaults = @getDefaults(req)
      cookie = req.cookies[@toggleName()] or '{}'
      userConfig = @createUserConfig(JSON.parse(cookie), if parseInt(req.headers["x-bot"]) then true else false)
      @overrideByHeader(userConfig, req)
      @overrideByQueryParam(userConfig, req)
      featureVals = @createFeatureVals(userConfig)
      req.ftoggle = new RequestDecoration(userConfig, featureVals, @toggleConfig)
      cookieOptions = @toggleConfig.cookieOptions || {}
      for k, v of defaults
        cookieOptions[k] = cookieOptions[k] or v
      res.cookie(@toggleName(), JSON.stringify(userConfig), cookieOptions)
      next()

  setConfig: (newConfig) ->
    @toggleConfig = newConfig
    @setUnstickyFeatures(newConfig, [])
    this

  setUnstickyFeatures: (conf, path) ->
    _(conf.features).keys().each((k, v) =>
      path.push k
      if conf.features[k].unsticky
        @unstickyFeatures.push path.join('.')
      if conf.features[k].features
        @setUnstickyFeatures conf.features[k], path
    ).value()

  addConfig: (newFeatureConf) ->
    @toggleConfig = merger.merge(@toggleConfig, newFeatureConf)

  #private

  toggleName: -> "ftoggle-#{@toggleConfig.name}"

  overrideByQueryParam: (userConfig, req) ->
    new OverridesToggleConfig(@toggleConfig, userConfig).
      override(req.query["#{@toggleName()}-on"], true).
      override(req.query["#{@toggleName()}-off"], false)

  overrideByHeader: (userConfig, req) ->
    new OverridesToggleConfig(@toggleConfig, userConfig).
      override(req.headers["x-#{@toggleName()}-on"], true).
      override(req.headers["x-#{@toggleName()}-off"], false)

  createUserConfig: (cookie, bot) ->
    if !_.isEmpty(cookie) and @cookieIsCurrent(cookie)
      if @unstickyFeatures.length
        _.each @unstickyFeatures, (feature) =>
          featurePath = "features.#{feature.replace('.', '.features.')}"
          subConfig = _.get(@toggleConfig, featurePath)
          _.set cookie, feature, @buildsUserConfig.build(subConfig, {}, false, bot)
      return cookie
    else
    @buildsUserConfig.build(@toggleConfig, {}, false, bot)

  createFeatureVals: (userConfig) ->
    @buildsFeatureVals.build(userConfig, @toggleConfig)

  cookieIsCurrent: (cookie) ->
    return false unless cookie?
    return true unless @toggleConfig.version?
    cookie.v == @toggleConfig.version

  getDefaults: (req) ->
    parts = req.get('host').split(':')[0].split('.')
    if parts.length > 2
      parts[0] = ''
    defaults =
      domain: parts.join('.')
      path: '/'
      maxAge: 63072000000
    return defaults
