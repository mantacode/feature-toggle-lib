(function() {
  var RequestDecoration, _;

  _ = typeof window !== 'undefined' && window._ ? window._ : require('lodash');

  module.exports = RequestDecoration = (function() {
    function RequestDecoration(config, cookie, featureVals, toggleConfig) {
      this.config = config;
      this.cookie = cookie;
      this.featureVals = featureVals != null ? featureVals : {};
      this.toggleConfig = toggleConfig != null ? toggleConfig : {};
    }

    RequestDecoration.prototype.isFeatureEnabled = function(feature, trueCallback, falseCallback) {
      return _.has(this.config, feature);
    };

    RequestDecoration.prototype.findEnabledChildren = function(prefix) {
      return _(_.get(this.config, prefix)).keys().without('e').value();
    };

    RequestDecoration.prototype.doesFeatureExist = function(feature) {
      return _.has(this.toggleConfig, this.makeFeaturePath(feature));
    };

    RequestDecoration.prototype.getFeatures = function() {
      return this.config;
    };

    RequestDecoration.prototype.featureVal = function(key) {
      return this.featureVals[key] || null;
    };

    RequestDecoration.prototype.getFeatureVals = function() {
      return this.featureVals;
    };

    RequestDecoration.prototype.enable = function(feature) {
      var current, parts;
      if (_.has(this.toggleConfig, this.makeFeaturePath(feature))) {
        parts = feature.split('.');
        current = '';
        while (parts.length > 0) {
          current += (current ? '.' : '') + parts.shift();
          if (_.get(this.toggleConfig, this.makeFeaturePath(current) + '.exclusiveSplit')) {
            this.del(this.config, current);
          }
          _.set(this.config, current + '.e', 1);
        }
        this.cookie(this.toggleName(), JSON.stringify(this.config), this.toggleConfig.cookieOptions);
      }
      return this;
    };

    RequestDecoration.prototype.disable = function(feature) {
      if (_.has(this.toggleConfig, this.makeFeaturePath(feature))) {
        this.del(this.config, feature);
        this.cookie(this.toggleName(), JSON.stringify(this.config), this.toggleConfig.cookieOptions);
      }
      return this;
    };

    RequestDecoration.prototype.toggleName = function() {
      return "ftoggle-" + this.toggleConfig.name;
    };

    RequestDecoration.prototype.makeFeaturePath = function(feature) {
      return 'features.' + feature.split('.').join('.features.');
    };

    RequestDecoration.prototype.del = function(obj, prop) {
      var parts, subobj, subpath;
      if (prop.indexOf('.') === -1) {
        delete obj[prop];
      } else {
        parts = prop.split('.');
        subpath = parts.slice(0, -1).join('.');
        subobj = _.get(obj, subpath);
        if (_.isPlainObject(subobj)) {
          delete subobj[parts[parts.length - 1]];
        }
      }
      return obj;
    };

    return RequestDecoration;

  })();

}).call(this);
