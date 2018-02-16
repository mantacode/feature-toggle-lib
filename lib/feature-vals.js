const _ = require('lodash');

const build = exports.build = function(userConfig, toggleConfig) {
  if (!userConfig || !userConfig.e) {
    return {};
  }

  let startVal = toggleConfig && toggleConfig.conf ? _.clone(toggleConfig.conf) : {};

  return _(userConfig).omit([ 'v', 'e' ])
    .reduce((memo, val, key) => {
      return Object.assign(memo, build(val, toggleConfig.features[key]));
    }, startVal);
};
