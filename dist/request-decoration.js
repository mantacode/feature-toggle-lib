(function() {
  var RequestDecoration, _;

  _ = typeof window !== 'undefined' && window._ ? window._ : require('lodash');

  module.exports = RequestDecoration = (function() {
    function RequestDecoration(config, featureVals, toggleConfig) {
      this.config = config;
      this.featureVals = featureVals != null ? featureVals : {};
      this.toggleConfig = toggleConfig != null ? toggleConfig : {};
    }

    RequestDecoration.prototype.isFeatureEnabled = function(feature, trueCallback, falseCallback) {
      var enabled, featureNodes;
      featureNodes = this.lookupFeature(feature.split("."), _.clone(this.config));
      if (enabled = (featureNodes != null) && (featureNodes !== false) && featureNodes.e) {
        if (typeof trueCallback === "function") {
          trueCallback(feature);
        }
      } else {
        if (typeof falseCallback === "function") {
          falseCallback(feature);
        }
      }
      return Boolean(enabled);
    };

    RequestDecoration.prototype.findEnabledChildren = function(prefix) {
      var children, feature, p;
      p = [];
      if (prefix != null) {
        p = prefix.split(".");
      }
      feature = this.lookupFeature(p, this.config);
      if (!feature) {
        return [];
      }
      children = _.filter(_.keys(feature), function(k) {
        return feature[k].e === 1;
      });
      if (children != null) {
        return children;
      } else {
        return [];
      }
    };

    RequestDecoration.prototype.doesFeatureExist = function(feature) {
      return _.has(this.toggleConfig, 'features.' + feature.replace('.', '.features.'));
    };

    RequestDecoration.prototype.getFeatures = function() {
      return this.config;
    };

    RequestDecoration.prototype.featureVal = function(key) {
      if (this.featureVals[key] != null) {
        return this.featureVals[key];
      } else {
        return null;
      }
    };

    RequestDecoration.prototype.getFeatureVals = function() {
      return this.featureVals;
    };

    RequestDecoration.prototype.lookupFeature = function(path, nodes, enabledOverride) {
      var current;
      if (enabledOverride == null) {
        enabledOverride = null;
      }
      current = path.shift();
      if (enabledOverride != null) {
        nodes.e = enabledOverride;
      }
      if ((current != null) && (nodes != null)) {
        if (nodes.e == null) {
          enabledOverride = false;
        }
        if ((enabledOverride != null) && enabledOverride === false) {
          return false;
        }
        return this.lookupFeature(path, nodes[current], enabledOverride);
      } else {
        return nodes;
      }
    };

    return RequestDecoration;

  })();

}).call(this);
