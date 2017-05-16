var _ = require('lodash')

var confFor = function(toggleConfig) {
  return toggleConfig && toggleConfig.conf ? _.clone(toggleConfig.conf) : {}
};

var build = exports.build = function(userConfig, toggleConfig) {
  if (!userConfig || !userConfig.e) {
    return {};
  }

  return _(userConfig).omit(['v', 'e']).reduce(function(memo, val, key) {
    memo = _.extend(memo, build(val, toggleConfig.features[key]));
    return memo;
  }, confFor(toggleConfig));
};
