var ftoggle = {};

ftoggle.toggleConfig = {};

ftoggle.roll = Math.random;

ftoggle.runConfig = function(config) {
  var self = this;
  var out = { enabled: config.hasOwnProperty('traffic') ? self.roll() <= config.traffic : true };
  if (config['version']) { out.version = config['version']; }
  if (out.enabled && config.features) {
    Object.keys(config.features).forEach(function (k) {
      out[k] = self.runConfig(config.features[k]);
    });
  }
  return out;
};

ftoggle.setConfig = function(newConfig) {
  this.toggleConfig = newConfig;
  return this.toggleConfig;
};

ftoggle.getConfig = function() {
  return this.toggleConfig;
};

ftoggle.lookupFeature = function(name, scores) {
  var self = this;
  var parts = typeof(name) === 'string' ? name.split('.') : name;
  var examine = parts.shift();
  if (scores[examine] && scores[examine].enabled) {
    return parts.length > 0 ? self.lookupFeature(parts, scores[examine]) : true;
  }
  else {
    return false;
  }
};

ftoggle.cookieIsCurrent = function(cookie) {
  var configVersion = this.toggleConfig.version;
  if (! cookie) return false;
  if (! configVersion) return true;
  if (configVersion === cookie.version) return true;
  return false;
};

var applyToggles = function(parts, data, val) {
  var thisPart = parts.shift();
  if (data[thisPart]) {
    if (parts.length < 1) {
      data[thisPart].enabled = val;
    } else {
      applyToggles(parts, data[thisPart], val);
    }
  }
};

ftoggle.newMiddleware = function() {
  var self = this;
  return function(req, res, next) {
    var cfgResults = {};
    var toggleName = 'ftoggle-' + self.toggleConfig.name;

    cookie = req.cookies[toggleName];

    if (self.cookieIsCurrent(cookie)) {
      cfgResults = cookie;
    } else {
      cfgResults = self.runConfig(self.toggleConfig);
    }

    if (req.param(toggleName + '-on')) {
      var ontoggles = req.param(toggleName + '-on').split(',');
      applyToggles(ontoggles, cfgResults, true);
    } 

    if (req.param(toggleName + '-off')) {
      var offtoggles = req.param(toggleName + '-off').split(',');
      applyToggles(offtoggles, cfgResults, false);
    } 

    res.cookie(toggleName, cfgResults);

    req.ftoggle = {
      isFeatureEnabled: function(feature, trueCallback, falseCallback) {
        var enabled = self.lookupFeature(feature, cfgResults);
        if (enabled && trueCallback)   trueCallback(feature);
        if (!enabled && falseCallback) falseCallback(feature);
        return enabled;
      }
    };
  };
};

exports.makeFtoggle = function() {
  return Object.create(ftoggle);
};

