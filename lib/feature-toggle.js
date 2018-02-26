const Ftoggle = require('./ftoggle');
const toggleBuilder = require('./toggle-builder');
const settingsBuilder = require('./settings-builder');
const _ = require('lodash');

class FeatureToggle {
  constructor(config) {
    this.featureConfig = config || {};
  }

  create(serialization) {
    const toggles = this.createUserConfig(serialization);
    const settings = settingsBuilder.build(toggles, this.featureConfig);
    return new Ftoggle(toggles, settings, this.featureConfig);
  }

  setConfig(config) {
    this.featureConfig = config;
    return this;
  }

  addConfig(config) {
    this.featureConfig = _.merge(this.featureConfig, config);
    return this;
  }

  createUserConfig(serialization) {
    const toggles = toggleBuilder.build(this.featureConfig, false);

    if (serialization && this.configIsCurrent(serialization)) {
      return Ftoggle.deserialize(serialization, toggles);
    } else {
      return toggles;
    }
  }

  configIsCurrent(serialization) {
    return typeof serialization !== 'undefined'
      && this.featureConfig.version
      && Number(serialization.split('z')[0]) === this.featureConfig.version;
  }
}

module.exports = FeatureToggle;
