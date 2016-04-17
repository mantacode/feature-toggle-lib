Ftoggle = require('./ftoggle')
confBuilder = require('./user-config')
featureBuilder = require('./feature-vals')
_ = require 'lodash'

module.exports = class FeatureToggle

  constructor: ->
    @toggleConfig = {}

  createConfig: (req, res, next) =>
    defaults = @getDefaults(req)
    cookie = req.cookies[ "ftoggle-#{@toggleConfig.name}" ] or '{}'
    try
      cookie = JSON.parse(cookie)
    catch e
      cookie = {}
    userConfig = @createUserConfig(cookie, if parseInt(req.headers["x-bot"]) then true else false)
    featureVals = featureBuilder.build(userConfig, @toggleConfig)

    cookieOptions = @toggleConfig.cookieOptions || {}
    for k, v of defaults
      cookieOptions[k] = cookieOptions[k] or v
    @toggleConfig.cookieOptions = cookieOptions
    req.ftoggle = new Ftoggle(userConfig, featureVals, @toggleConfig)
    @overrideByHeader(userConfig, req)
    @overrideByQueryParam(userConfig, req)
    next()

  setCookie: (req, res, next) =>
    res.cookie(req.ftoggle.toggleName(), JSON.stringify(req.ftoggle.config), @toggleConfig.cookieOptions)
    next()

  setConfig: (newConfig) ->
    @toggleConfig = newConfig
    this

  addConfig: (newFeatureConf) ->
    @toggleConfig = _.merge(@toggleConfig, newFeatureConf)
    this

  #private

  overrideByQueryParam: (userConfig, req) ->
    enable = req.query[ req.ftoggle.toggleName() + '-on' ]
    disable = req.query[ req.ftoggle.toggleName() + '-off' ]
    if enable
      req.ftoggle.enableAll(enable)
    if disable
      req.ftoggle.disableAll(disable)

  overrideByHeader: (userConfig, req) ->
    enable = req.headers[ 'x-' + req.ftoggle.toggleName() + '-on' ]
    disable = req.headers[ 'x-' + req.ftoggle.toggleName() + '-off' ]
    if enable
      req.ftoggle.enableAll(enable)
    if disable
      req.ftoggle.disableAll(disable)

  createUserConfig: (cookie, bot) ->
    # If a cookie is already set and it's current, then we'll
    # keep all those toggles and not recalculate
    if !_.isEmpty(cookie) and @cookieIsCurrent(cookie)
      return cookie
    else
      # If there's no cookie, build the whole thing now
      confBuilder.build(@toggleConfig, false, bot)

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
