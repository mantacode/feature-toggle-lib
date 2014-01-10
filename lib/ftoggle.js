toggleConfig = {};

exports.newMiddleware = function() {
  return function(req, res, next) {
    req.ftoggle = {
      isFeatureEnabled: function(feature, trueCallback, falseCallback) {
        return false;
      },
      getConfig: function() {
        return toggleConfig;
      },
      setConfig: function(newConfig) {
        toggleConfig = newConfig;
        return toggleConfig;
      }
    };
  };
};
