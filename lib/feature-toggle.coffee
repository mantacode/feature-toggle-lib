math = require('./math')
OverridesToggleConfig = require('./overrides-toggle-config')
RequestDecoration = require('./request-decoration')
BuildsUserConfig = require('./builds-user-config')
BuildsFeatureVals = require('./builds-feature-vals')
merger = require('./merger')

module.exports = class FeatureToggle

  constructor: ->
    @toggleConfig = {}
    @buildsUserConfig = new BuildsUserConfig(math)
    @buildsFeatureVals = new BuildsFeatureVals()

  newMiddleware: ->
    (req, res, next) =>
      defaults = @getDefaults(req)
      userConfig = @createUserConfig(req.cookies[@toggleName()], if parseInt(req.headers["x-bot"]) then true else false)
      @overrideByHeader(userConfig, req)
      @overrideByQueryParam(userConfig, req)
      featureVals = @createFeatureVals(userConfig)
      req.ftoggle = new RequestDecoration(userConfig, featureVals)
      cookieOptions = @toggleConfig.cookieOptions || {}
      for k, v of defaults
        cookieOptions[k] = cookieOptions[k] or v
      res.cookie(@toggleName(), userConfig, cookieOptions)
      next()

  setConfig: (newConfig) ->
    @toggleConfig = newConfig
    this

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
    base = cookie
    base = {} if not @cookieIsCurrent(cookie)
    @buildsUserConfig.build(@toggleConfig, base, false, bot)

  createFeatureVals: (userConfig) ->
    @buildsFeatureVals.build(userConfig, @toggleConfig)

  cookieIsCurrent: (cookie) ->
    return false unless cookie?
    return true unless @toggleConfig.version?
    cookie.version == @toggleConfig.version

  getDefaults: (req) ->
    parts = req.get('host').split(':')[0].split('.')
    if parts.length > 2
      parts[0] = ''
    defaults =
      domain: parts.join('.')
      path: '/'
      maxAge: 63072000000
    return defaults
