(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.FtoggleRequestDecoration = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
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

    RequestDecoration.prototype.enable = function(feature) {
      var current, parts;
      if (_.has(this.toggleConfig, this.makeFeaturePath(feature))) {
        parts = feature.split('.');
        current = '';
        while (parts.length > 0) {
          current += (current ? '.' : '') + parts.shift();
          if (_.get(this.toggleConfig, this.makeFeaturePath(current) + '.exclusiveSplit')) {
            _.unset(this.config, current);
          }
          _.set(this.config, current + '.e', 1);
        }
        this.cookie(this.toggleName(), JSON.stringify(this.config), this.toggleConfig.cookieOptions);
      }
      return this;
    };

    RequestDecoration.prototype.disable = function(feature) {
      if (_.has(this.toggleConfig, this.makeFeaturePath(feature))) {
        _.unset(this.config, feature);
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

    return RequestDecoration;

  })();

}).call(this);

},{"lodash":undefined}]},{},[1])(1)
});