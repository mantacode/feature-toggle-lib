(function() {
  var RequestDecoration, _;

  _ = typeof window !== 'undefined' && window._ ? window._ : require('lodash');

  module.exports = RequestDecoration = (function() {
    function RequestDecoration(config1, cookie, featureVals, toggleConfig) {
      this.config = config1;
      this.cookie = cookie;
      this.featureVals = featureVals != null ? featureVals : {};
      this.toggleConfig = toggleConfig != null ? toggleConfig : {};
    }

    RequestDecoration.prototype.isFeatureEnabled = function(feature, trueCallback, falseCallback) {
      return Boolean(_.get(this.config, feature + '.e'));
    };

    RequestDecoration.prototype.findEnabledChildren = function(prefix) {
      var subset;
      subset = prefix ? _.get(this.config, prefix) : this.config;
      return _(subset).keys().without('e').value();
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

    RequestDecoration.prototype.setFeatures = function(ftr) {
      var featureConf;
      featureConf = _.get(this.toggleConfig, ftr + '.conf');
      _.each(featureConf, (function(_this) {
        return function(v, k) {
          return _this.featureVals[k] = v;
        };
      })(this));
      return this;
    };

    RequestDecoration.prototype.unsetFeatures = function(ftr) {
      var featureConf;
      featureConf = _.get(this.toggleConfig, ftr + '.conf');
      _.each(featureConf, (function(_this) {
        return function(v, k) {
          return delete _this.featureVals[k];
        };
      })(this));
      return this;
    };

    RequestDecoration.prototype.enable = function(feature) {
      var current, currentConfig, featurePath, innerFeaturePath, parts;
      featurePath = this.makeFeaturePath(feature);
      if (_.has(this.toggleConfig, featurePath)) {
        parts = feature.split('.');
        current = '';
        while (parts.length > 0) {
          current += (current ? '.' : '') + parts.shift();
          innerFeaturePath = this.makeFeaturePath(current);
          currentConfig = _.get(this.toggleConfig, innerFeaturePath);
          if (currentConfig != null ? currentConfig.exclusiveSplit : void 0) {
            _.unset(this.config, current);
            _.each(currentConfig.features, (function(_this) {
              return function(v, k) {
                return _this.unsetFeatures(innerFeaturePath + '.features.' + k);
              };
            })(this));
          }
          _.set(this.config, current + '.e', 1);
          this.setFeatures(innerFeaturePath);
        }
        this.cookie(this.toggleName(), JSON.stringify(this.config), this.toggleConfig.cookieOptions);
      }
      return this;
    };

    RequestDecoration.prototype.disable = function(feature) {
      var featurePath;
      featurePath = this.makeFeaturePath(feature);
      if (_.has(this.toggleConfig, featurePath)) {
        _.unset(this.config, feature);
        this.unsetFeatures(featurePath);
        _.each(this.getAllChildNodes(this.toggleConfig, featurePath), (function(_this) {
          return function(node) {
            return _this.unsetFeatures(node);
          };
        })(this));
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

    RequestDecoration.prototype.getAllChildNodes = function(config, path) {
      var thisConfig;
      thisConfig = _.get(config, path + '.features');
      return _.reduce(thisConfig, (function(_this) {
        return function(memo, v, k) {
          var inner;
          inner = path + '.features.' + k;
          memo.push(inner);
          _.each(_this.getAllChildNodes(thisConfig, k), function(child) {
            return memo.push(path + '.features.' + child);
          });
          return memo;
        };
      })(this), []);
    };

    return RequestDecoration;

  })();

}).call(this);
