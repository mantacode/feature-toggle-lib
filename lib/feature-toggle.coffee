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
      try
        cookie = JSON.parse(cookie)
      catch e
        res.clearCookie @toggleName(), { domain: '.manta.com', path: '/' }
        cookie = {}
      userConfig = @createUserConfig(cookie, if parseInt(req.headers["x-bot"]) then true else false)
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
    # Figure out a list of unsticky features
    @setUnstickyFeatures(newConfig, [])
    this

  setUnstickyFeatures: (conf, path) ->
    # Loop over the top level features
    _.each conf.features, (v, k) =>
      # Add this key to the path
      path.push k
      # If this feature is unsticky, add the
      # current path to the list
      if conf.features[k].unsticky
        @unstickyFeatures.push path.join('.')

      # If this feature is an object with subfeatures,
      # recurse over those features
      if conf.features[k].features
        @setUnstickyFeatures conf.features[k], path

    # Let's not return the result of _.each, which is
    # . . . ?
    return

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
    # If a cookie is already set and it's current, then we'll
    # keep all those toggles and not recalculate
    if !_.isEmpty(cookie) and @cookieIsCurrent(cookie)
      # EXCEPT for any unsticky features, but for those,
      # we'll ONLY recalculate the unsticky parts of the tree,
      # and extend the existine cookie
      if @unstickyFeatures.length
        # Loop over pre-determined unsticky features
        _.each @unstickyFeatures, (feature) =>

          # Build the path to the feature in the form features.x.features.y.features.z
          featurePath = "features.#{feature.replace('.', '.features.')}"

          # Get the config at that path
          subConfig = _.get(@toggleConfig, featurePath)

          # Rebuild that part of the config
          rebuiltConfig = @buildsUserConfig.build(subConfig, {}, false, bot)

          # Set the same path (but without '.feature.') in the cookie
          _.set cookie, feature, rebuiltConfig

      return cookie
    else
      # If there's no cookie, build the whole thing now
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
