const Ftoggle = require('./ftoggle');
const confBuilder = require('./user-config');
const featureBuilder = require('./feature-vals');
const _ = require('lodash');

class FeatureToggle {
  constructor() {
    this.toggleConfig = {};
  }

  createConfig(cookie) {
    const userConfig = this.createUserConfig(cookie);
    const featureVals = featureBuilder.build(userConfig, this.toggleConfig);
    return new Ftoggle(userConfig, featureVals, this.toggleConfig);
  }

  setConfig(config) {
    this.toggleConfig = config;
    return this;
  }

  addConfig(config) {
    this.toggleConfig = _.merge(this.toggleConfig, config);
    return this;
  }

  createUserConfig(cookie) {
    const conf = confBuilder.build(this.toggleConfig, false);

    if (cookie && this.cookieIsCurrent(cookie)) {
      return Ftoggle.getUnpackedConfig(cookie, conf);
    } else {
      return conf;
    }
  }

  cookieIsCurrent(cookie) {
    return typeof cookie !== 'undefined'
      && this.toggleConfig.version
      && Number(cookie.split('z')[0]) === this.toggleConfig.version;
  }
}

module.exports = FeatureToggle;

// FeatureToggle.prototype.setCookie = function(req, res, next) {
//   res.cookie(req.ftoggle.toggleName(), req.ftoggle.getPackedConfig(), { maxAge: TWO_YEARS });
//   next();
// };

