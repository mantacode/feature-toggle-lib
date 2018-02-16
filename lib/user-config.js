const _ = require('lodash');
const math = require('./math');

const pickWinner = function(features) {
  let floor = 0;
  let rand = math.random();
  let winner = null;

  for (let name in features) {
    let feature = features[name];
    let traffic = feature.traffic;
    if (traffic) {
      let ceiling = floor + traffic;
      if (floor <= rand && ceiling > rand) {
        winner = name;
        break;
      } else {
        floor = ceiling;
      }
    }
  }

  return winner;
};

const build = exports.build = function(config, alreadyPicked, parentDisabled) {
  if (!config) {
    return {};
  }

  let userConfig = {};
  if (config.version) {
    userConfig.v = config.version;
  }

  if ((!parentDisabled && typeof config.traffic !== 'undefined' && math.random() <= config.traffic) || alreadyPicked || config.version) {
    userConfig.e = 1;
  } else {
    userConfig.e = 0;
    parentDisabled = true;
  }

  if (config.exclusiveSplit) {
    let pick = pickWinner(config.features);
    if (pick) {
      userConfig[pick] = build(config.features[pick], !parentDisabled ? true : false, parentDisabled);
    }
    return _.reduce(config.features, function(memo, feature, name) {
      if (name !== pick) {
        memo[name] = build(feature, false, true);
        if (_.isEmpty(memo[name])) {
          delete memo[name];
        }
      }
      return memo;
    }, userConfig);
  } else {
    return _.reduce(config.features, function(memo, feature, name) {
      memo[name] = build(feature, false, parentDisabled);
      if (_.isEmpty(memo[name])) {
        delete memo[name];
      }
      return memo;
    }, userConfig);
  }
};
