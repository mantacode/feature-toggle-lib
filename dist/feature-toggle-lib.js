(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.FtoggleRequestDecoration = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function() {
  var RequestDecoration;

  module.exports = RequestDecoration = (function() {
    function RequestDecoration(config, featureVals) {
      this.config = config;
      this.featureVals = featureVals != null ? featureVals : {};
    }

    RequestDecoration.prototype.isFeatureEnabled = function(feature, trueCallback, falseCallback) {
      var enabled, featureNodes;
      featureNodes = this.lookupFeature(feature.split("."), this.objClone(this.config));
      if (enabled = (featureNodes != null) && (featureNodes !== false) && featureNodes.enabled) {
        if (typeof trueCallback === "function") {
          trueCallback(feature);
        }
      } else {
        if (typeof falseCallback === "function") {
          falseCallback(feature);
        }
      }
      return enabled;
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
      children = this.filter(Object.keys(feature), function(k) {
        return feature[k].enabled === true;
      });
      if (children != null) {
        return children;
      } else {
        return [];
      }
    };

    RequestDecoration.prototype.doesFeatureExist = function(feature) {
      var nodes;
      nodes = this.lookupFeature(feature.split("."), this.config);
      return nodes != null;
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
        nodes.enabled = enabledOverride;
      }
      if ((current != null) && (nodes != null)) {
        if ((nodes.enabled == null) || nodes.enabled === false) {
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

    RequestDecoration.prototype.filter = function(list, f) {
      var out;
      out = [];
      list.forEach(function(e) {
        if (f(e)) {
          return out.push(e);
        }
      });
      return out;
    };

    RequestDecoration.prototype.objClone = function(o) {
      var k, out, v;
      if (typeof o === 'object') {
        out = {};
        for (k in o) {
          v = o[k];
          out[k] = this.objClone(v);
        }
        return out;
      } else {
        return o;
      }
    };

    return RequestDecoration;

  })();

}).call(this);

},{}]},{},[1])(1)
});