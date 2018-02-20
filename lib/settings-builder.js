const _ = require('lodash');

const build = exports.build = function(toggles, featureConfig) {
  if (!toggles || !toggles.e) {
    return {};
  }

  let settings = featureConfig && featureConfig.settings ? { ...featureConfig.settings } : {};

  return _(toggles).omit([ 'v', 'e' ])
    .reduce((memo, val, key) => {
      return Object.assign(memo, build(val, featureConfig.features[key]));
    }, settings);
};
