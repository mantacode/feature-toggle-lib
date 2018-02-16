const _ = require('./lodash');
const packer = require('./packer');

class Ftoggle {
  constructor(config, featureVals, toggleConfig) {
    this.config = config;
    this.toggleConfig = toggleConfig || {};
    this.featureVals = featureVals || {};
  }

  isFeatureEnabled(feature) {
    return Boolean(_.get(this.config, `${feature}.e`));
  }

  findEnabledChildren(parent) {
    let subset = parent ? _.get(this.config, parent) : this.config;
    return _(subset)
      .keys()
      .without('e', 'v')
      .filter((k) => subset[k].e)
      .value();
  }

  doesFeatureExist(feature) {
    return _.has(this.toggleConfig, this.makeFeaturePath(feature));
  }

  getFeatures() {
    return this.config;
  }

  featureVal(key) {
    return this.featureVals[key] || null;
  }

  getFeatureVals() {
    return this.featureVals;
  }

  getConfigForFeature(feature) {
    return _.get(this.toggleConfig, `${feature}.conf`);
  }

  setFeatures(feature) {
    let featureConf = this.getConfigForFeature(feature);
    _.each(featureConf, (value, key) => {
      this.featureVals[key] = value;
    });
    return this;
  }

  unsetFeatures(feature) {
    let featureConf = this.getConfigForFeature(feature);
    _.each(featureConf, (value, key) => {
      delete this.featureVals[key];
    });
    return this;
  }

  enable(feature) {
    let featurePath = this.makeFeaturePath(feature);
    if (_.has(this.toggleConfig, featurePath)) {
      let parts = feature.split('.');
      let current = '';
      const unset = (innerFeaturePath) => (value, key) => {
        this.unsetFeatures(`${innerFeaturePath}.features.${key}`);
      };
      while (parts.length > 0) {
        current += (current ? '.' : '') + parts.shift();
        let innerFeaturePath = this.makeFeaturePath(current);
        let currentConfig = _.get(this.toggleConfig, innerFeaturePath);
        if (currentConfig && currentConfig.exclusiveSplit) {
          this.unsetAll(_.get(this.config, current));
          _.each(currentConfig.features, unset(innerFeaturePath));
        }

        _.set(this.config, `${current}.e`, 1);
        this.setFeatures(innerFeaturePath);
      }
    }
    return this;
  }

  enableAll(features) {
    if (!_.isArray(features)) {
      features = features.split(',');
    }

    _.each(features, this.enable.bind(this));
  }

  disable(feature) {
    let featurePath = this.makeFeaturePath(feature);
    if (_.has(this.toggleConfig, featurePath)) {
      this.unsetAll(_.get(this.config, feature));
      this.unsetFeatures(featurePath);
      _.each(this.getAllChildNodes(this.toggleConfig, featurePath), (node) => {
        this.unsetFeatures(node);
      });
    }
    return this;
  }

  disableAll(features) {
    if (!_.isArray(features)) {
      features = features.split(',');
    }

    _.each(features, this.disable.bind(this));
  }

  toggleName() {
    return `ftoggle-${this.toggleConfig.name}`;
  }

  makeFeaturePath(feature) {
    return `features.${feature.split('.').join('.features.')}`;
  }

  getAllChildNodes(config, path) {
    let thisConfig = _.get(config, `${path}.features`);
    return _.reduce(thisConfig, (memo, val, key) => {
      let inner = `${path}.features.${key}`;
      memo.push(inner);
      _.each(this.getAllChildNodes(thisConfig, key), (child) => {
        memo.push(`${path}.features.${child}`);
      });
      return memo;
    }, []);
  }

  unsetAll(config) {
    config.e = 0;
    _.each(config, (val, key) => {
      if (key !== 'e') {
        this.unsetAll(config[key]);
      }
    });
  }

  getPackedConfig() {
    return packer.pack(this.config);
  }

  // Not a typo. This is not on prototype because
  // you need this function to generate the config
  // that is required to create an instance of Ftoggle.
  static getUnpackedConfig(cookie, conf) {
    return packer.unpack(cookie, conf);
  }
}

module.exports = Ftoggle;
