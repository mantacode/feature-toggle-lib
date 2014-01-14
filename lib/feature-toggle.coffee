math = require('./math')
OverridesToggleConfig = require('./overrides-toggle-config')
RequestDecoration = require('./request-decoration')
BuildsUserConfig = require('./builds-user-config')

module.exports = class FeatureToggle

  constructor: ->
    @toggleConfig = {}
    @buildsUserConfig = new BuildsUserConfig(math)

  newMiddleware: ->
    (req, res, next) =>
      userConfig = @createUserConfig(req.cookies[@toggleName()])
      @overrideByQueryParam(userConfig, req)
      req.ftoggle = new RequestDecoration(userConfig)
      res.cookie(@toggleName(), userConfig)
      next()

  setConfig: (newConfig) ->
    @toggleConfig = newConfig

  #private

  toggleName: -> "ftoggle-#{@toggleConfig.name}"

  overrideByQueryParam: (userConfig, req) ->
    new OverridesToggleConfig(userConfig).
      override(req.param("#{@toggleName()}-on"), true).
      override(req.param("#{@toggleName()}-off"), false)


  createUserConfig: (cookie) ->
    return cookie if @cookieIsCurrent(cookie)
    @buildsUserConfig.build(@toggleConfig)

  cookieIsCurrent: (cookie) ->
    return false unless cookie?
    return true unless @toggleConfig.version?
    cookie.version == @toggleConfig.version

