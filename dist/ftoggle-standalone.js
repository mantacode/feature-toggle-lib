(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.Ftoggle = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var _ = typeof window !== 'undefined' && window._ ? window._ : require('lodash');

var Ftoggle = module.exports = function(config, featureVals, toggleConfig) {
  this.config = config;
  this.toggleConfig = toggleConfig || {};
  this.featureVals = featureVals || {};
};

Ftoggle.prototype.isFeatureEnabled = function(feature) {
  return Boolean(_.get(this.config, feature + '.e'));
};

Ftoggle.prototype.findEnabledChildren = function(parent) {
  var subset = parent ? _.get(this.config, parent) : this.config;
  return _(subset).keys().without('e', 'v').value()
};

Ftoggle.prototype.doesFeatureExist = function(feature) {
  return _.has(this.toggleConfig, this.makeFeaturePath(feature));
};

Ftoggle.prototype.getFeatures = function() {
  return this.config;
};

Ftoggle.prototype.featureVal = function(key) {
  return this.featureVals[key] || null;
};

Ftoggle.prototype.getFeatureVals = function() {
  return this.featureVals;
};

Ftoggle.prototype.getConfigForFeature = function(feature) {
  return _.get(this.toggleConfig, feature + '.conf');
};

Ftoggle.prototype.setFeatures = function(feature) {
  var featureConf = this.getConfigForFeature(feature);
  _.each(featureConf, function(value, key) {
    this.featureVals[key] = value;
  }.bind(this));
  return this;
};

Ftoggle.prototype.unsetFeatures = function(feature) {
  var featureConf = this.getConfigForFeature(feature);
  _.each(featureConf, function(value, key) {
    delete this.featureVals[key];
  }.bind(this));
  return this;
};

Ftoggle.prototype.enable = function(feature) {
  var featurePath = this.makeFeaturePath(feature);
  if (_.has(this.toggleConfig, featurePath)) {
    var parts = feature.split('.');
    var current = '';
    while (parts.length > 0) {
      current += (current ? '.' : '') + parts.shift();
      var innerFeaturePath = this.makeFeaturePath(current);
      var currentConfig = _.get(this.toggleConfig, innerFeaturePath);
      if (currentConfig && currentConfig.exclusiveSplit) {
        _.unset(this.config, current);
        _.each(currentConfig.features, function(value, key) {
          this.unsetFeatures(innerFeaturePath + '.features.' + key);
        }.bind(this));
      }

      _.set(this.config, current + '.e', 1);
      this.setFeatures(innerFeaturePath);
    }
  }
  return this;
};

Ftoggle.prototype.enableAll = function(features) {
  if (!_.isArray(features)) {
    features = features.split(',');
  }
  
  _.each(features, this.enable.bind(this));
};

Ftoggle.prototype.disable = function(feature) {
  var featurePath = this.makeFeaturePath(feature);
  if (_.has(this.toggleConfig, featurePath)) {
    _.unset(this.config, feature);
    this.unsetFeatures(featurePath);
    _.each(this.getAllChildNodes(this.toggleConfig, featurePath), function(node) {
      this.unsetFeatures(node);
    }.bind(this));
  }
  return this;
};

Ftoggle.prototype.disableAll = function(features) {
  if (!_.isArray(features)) {
    features = features.split(',');
  }

  _.each(features, this.disable.bind(this));
};

Ftoggle.prototype.toggleName = function() {
  return 'ftoggle-' + this.toggleConfig.name;
};

Ftoggle.prototype.makeFeaturePath = function(feature) {
  return 'features.' + feature.split('.').join('.features.');
};

Ftoggle.prototype.getAllChildNodes = function(config, path) {
  var thisConfig = _.get(config, path + '.features');
  return _.reduce(thisConfig, function(memo, val, key) {
    var inner = path + '.features.' + key;
    memo.push(inner);
    _.each(this.getAllChildNodes(thisConfig, key), function(child) {
      memo.push(path + '.features.' + child);
    });
    return memo;
  }.bind(this), []);
};

},{"lodash":undefined}]},{},[1])(1)
});