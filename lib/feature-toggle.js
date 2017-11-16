var Ftoggle = require('./ftoggle');
var confBuilder = require('./user-config');
var featureBuilder = require('./feature-vals');
var _ = require('lodash');

var FeatureToggle = module.exports = function() {
  this.toggleConfig = {};
  this.createConfig = this.createConfig.bind(this);
  this.setCookie = this.setCookie.bind(this);
};

FeatureToggle.prototype.createConfig = function(req, res, next) {
  var defaults = this.getCookieDefaults(req);
  this.toggleConfig.cookieOptions = _.defaults({}, this.toggleConfig.cookieOptions || {}, defaults);
  var cookieName =  'ftoggle-' + this.toggleConfig.name ;
  var cookie = req.cookies[cookieName];
  var userConfig = this.createUserConfig(req, cookie, parseInt(req.headers['x-bot'], 10) ? true : false);
  var featureVals = featureBuilder.build(userConfig, this.toggleConfig);
  req.ftoggle = new Ftoggle(userConfig, featureVals, this.toggleConfig);
  this.overrideByHeader(req);
  this.overrideByQueryParam(req);
  next();
};

FeatureToggle.prototype.setCookie = function(req, res, next) {
  res.cookie(req.ftoggle.toggleName(), req.ftoggle.getPackedConfig(), this.toggleConfig.cookieOptions);
  next();
};

FeatureToggle.prototype.setConfig = function(config) {
  this.toggleConfig = config;
  return this;
};

FeatureToggle.prototype.addConfig = function(config) {
  this.toggleConfig = _.merge(this.toggleConfig, config);
  return this;
};

FeatureToggle.prototype.overrideByQueryParam = function(req) {
  var enable = req.query[ req.ftoggle.toggleName() + '-on' ];
  if (enable) {
    req.ftoggle.enableAll(enable);
  }

  var disable = req.query[ req.ftoggle.toggleName() + '-off' ];
  if (disable) {
    req.ftoggle.disableAll(disable);
  }
};

FeatureToggle.prototype.overrideByHeader = function(req) {
  var enable = req.header[ 'x-' + req.ftoggle.toggleName() + '-on' ];
  if (enable) {
    req.ftoggle.enableAll(enable);
  }

  var disable = req.header[ 'x-' + req.ftoggle.toggleName() + '-off' ];
  if (disable) {
    req.ftoggle.disableAll(disable);
  }
};

FeatureToggle.prototype.createUserConfig = function(req, cookie, bot) {
  var conf = confBuilder.build(this.toggleConfig, false, bot);

  if (cookie && this.cookieIsCurrent(cookie)) {
    return Ftoggle.getUnpackedConfig(cookie, conf);
  } else {
    return conf;
  }
};

FeatureToggle.prototype.cookieIsCurrent = function(cookie) {
  return typeof cookie !== 'undefined'
    && this.toggleConfig.version
    && Number(cookie.split('z')[0]) === this.toggleConfig.version;
}

FeatureToggle.prototype.getCookieDefaults = function(req) {
  var parts = req.get('host').split(':')[0].split('.');
  if (parts.length > 2) {
    parts[0] = '';
  }
  return {
    domain: parts.join('.'),
    path: '/',
    maxAge: 63072000000
  };
};
