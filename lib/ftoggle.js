const _ = require('./lodash');
const packer = require('./packer');

class Ftoggle {
  constructor(toggles, settings, featureConfig) {
    this.toggles = toggles;
    this.featureConfig = featureConfig || {};
    this.settings = settings || {};
    this.toggleName = `ftoggle-${this.featureConfig.name}`;
  }

  isFeatureEnabled(feature) {
    return Boolean(_.get(this.toggles, `${feature}.e`));
  }

  findEnabledChildren(parent) {
    let subset = parent ? _.get(this.toggles, parent) : this.toggles;
    return _(subset)
      .keys()
      .without('e', 'v')
      .filter((k) => subset[k].e)
      .value();
  }

  doesFeatureExist(feature) {
    return _.has(this.featureConfig, this.makeFeaturePath(feature));
  }

  getToggles() {
    return this.toggles;
  }

  getSetting(key) {
    return this.settings[key] || null;
  }

  getSettings() {
    return this.settings;
  }

  getSettingsForFeature(feature) {
    if (!feature) {
      return {};
    }

    return _.get(this.featureConfig, `${feature}.settings`);
  }

  setFeatureSettings(feature) {
    let featureConf = this.getSettingsForFeature(feature);
    _.each(featureConf, (value, key) => {
      this.settings[key] = value;
    });
    return this;
  }

  unsetFeatureSettings(feature) {
    let featureConf = this.getSettingsForFeature(feature);
    _.each(featureConf, (value, key) => {
      delete this.settings[key];
    });
    return this;
  }

  enable(feature) {
    let featurePath = this.makeFeaturePath(feature);
    if (_.has(this.featureConfig, featurePath)) {
      let parts = feature.split('.');
      let current = '';
      const unset = (innerFeaturePath) => (value, key) => {
        this.unsetFeatureSettings(`${innerFeaturePath}.features.${key}`);
      };
      while (parts.length > 0) {
        current += (current ? '.' : '') + parts.shift();
        let innerFeaturePath = this.makeFeaturePath(current);
        let currentConfig = _.get(this.featureConfig, innerFeaturePath);
        if (currentConfig && currentConfig.exclusiveSplit) {
          this.unsetAll(_.get(this.toggles, current));
          _.each(currentConfig.features, unset(innerFeaturePath));
        }

        _.set(this.toggles, `${current}.e`, 1);
        this.setFeatureSettings(innerFeaturePath);
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
    if (_.has(this.featureConfig, featurePath)) {
      this.unsetAll(_.get(this.toggles, feature));
      this.unsetFeatureSettings(featurePath);
      _.each(this.getAllChildNodes(this.featureConfig, featurePath), (node) => {
        this.unsetFeatureSettings(node);
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

  makeFeaturePath(feature) {
    return `features.${feature.split('.').join('.features.')}`;
  }

  getAllChildNodes(featureConfig, path) {
    let thisConfig = _.get(featureConfig, `${path}.features`);
    return _.reduce(thisConfig, (memo, val, key) => {
      let inner = `${path}.features.${key}`;
      memo.push(inner);
      _.each(this.getAllChildNodes(thisConfig, key), (child) => {
        memo.push(`${path}.features.${child}`);
      });
      return memo;
    }, []);
  }

  unsetAll(toggles) {
    toggles.e = 0;
    _.each(toggles, (val, key) => {
      if (key !== 'e') {
        this.unsetAll(toggles[key]);
      }
    });
  }

  serialize() {
    return packer.pack(this.toggles);
  }

  // Not a typo. This is not on prototype because
  // you need this function to generate the config
  // that is required to create an instance of Ftoggle.
  static deserialize(serialization, toggles) {
    return packer.unpack(serialization, toggles);
  }
}

module.exports = Ftoggle;
