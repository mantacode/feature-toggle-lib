const _ = require('lodash');
const math = require('./math');

const pickWinner = function(features) {
  let floor = 0;
  let rand = math.random();
  let winner = null;

  for (let name in features) {
    let traffic = features[name].traffic;
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

const build = exports.build = function(featureConfig, alreadyPicked, parentDisabled) {
  if (!featureConfig) {
    return {};
  }

  let toggles = {};
  if (featureConfig.version) {
    toggles.v = featureConfig.version;
  }

  if ((!parentDisabled && typeof featureConfig.traffic !== 'undefined' && math.random() <= featureConfig.traffic) || alreadyPicked || featureConfig.version) {
    toggles.e = 1;
  } else {
    toggles.e = 0;
    parentDisabled = true;
  }

  if (featureConfig.exclusiveSplit) {
    let pick = pickWinner(featureConfig.features);
    if (pick) {
      toggles[pick] = build(featureConfig.features[pick], !parentDisabled ? true : false, parentDisabled);
    }
    return _.reduce(featureConfig.features, function(memo, feature, name) {
      if (name !== pick) {
        memo[name] = build(feature, false, true);
        if (_.isEmpty(memo[name])) {
          delete memo[name];
        }
      }
      return memo;
    }, toggles);
  } else {
    return _.reduce(featureConfig.features, function(memo, feature, name) {
      memo[name] = build(feature, false, parentDisabled);
      if (_.isEmpty(memo[name])) {
        delete memo[name];
      }
      return memo;
    }, toggles);
  }
};
