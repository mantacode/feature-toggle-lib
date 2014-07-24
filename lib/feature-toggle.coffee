math = require('./math')
OverridesToggleConfig = require('./overrides-toggle-config')
RequestDecoration = require('./request-decoration')
BuildsUserConfig = require('./builds-user-config')
BuildsFeatureVals = require('./builds-feature-vals')

module.exports = class FeatureToggle

  constructor: ->
    @toggleConfig = {}
    @buildsUserConfig = new BuildsUserConfig(math)
    @buildsFeatureVals = new BuildsFeatureVals()

  newMiddleware: ->
    (req, res, next) =>
      userConfig = @createUserConfig(req.cookies[@toggleName()])
      @overrideByQueryParam(userConfig, req)
      featureVals = @createFeatureVals(userConfig)
      req.ftoggle = new RequestDecoration(userConfig, featureVals)
      res.cookie(@toggleName(), userConfig)
      next()

  setConfig: (newConfig) ->
    @toggleConfig = newConfig
    this

  #private

  toggleName: -> "ftoggle-#{@toggleConfig.name}"

  overrideByQueryParam: (userConfig, req) ->
    new OverridesToggleConfig(@toggleConfig, userConfig).
      override(req.param("#{@toggleName()}-on"), true).
      override(req.param("#{@toggleName()}-off"), false)

  createUserConfig: (cookie) ->
    return cookie if @cookieIsCurrent(cookie)
    @buildsUserConfig.build(@toggleConfig)

  createFeatureVals: (userConfig) ->
    @buildsFeatureVals.build(userConfig, @toggleConfig)

  cookieIsCurrent: (cookie) ->
    return false unless cookie?
    return true unless @toggleConfig.version?
    cookie.version == @toggleConfig.version

