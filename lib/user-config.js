var _ = require('lodash');
var math = require('./math');

var getTraffic = function(config, bot) {
  return typeof config.botTraffic !== 'undefined' && bot ? config.botTraffic : config.traffic;
};

var pickWinner = function(features, bot) {
  var floor = 0;
  var rand = math.random();
  var winner = null;

  for (var name in features) {
    var feature = features[name];
    var traffic = getTraffic(feature, bot);
    if (traffic) {
      var ceiling = floor + traffic;
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

var build = exports.build = function(config, alreadyPicked, bot, parentDisabled) {
  if (!config) {
    return {};
  }

  var userConfig = {};
  if (config.version) {
    userConfig.v = config.version;
  }

  if ((!parentDisabled && typeof config.traffic !== 'undefined' && math.random() <= getTraffic(config, bot)) || alreadyPicked || config.version) {
    userConfig.e = 1;
  } else {
    userConfig.e = 0;
    parentDisabled = true;
  }

  if (config.exclusiveSplit) {
    var pick = pickWinner(config.features, bot);
    if (pick) {
      userConfig[pick] = build(config.features[pick], !parentDisabled ? true : false, bot, parentDisabled);
    }
    return _.reduce(config.features, function(memo, feature, name) {
      if (name !== pick) {
        memo[name] = build(feature, false, bot, true);
        if (_.isEmpty(memo[name])) {
          delete memo[name];
        }
      }
      return memo;
    }, userConfig);
  } else {
    return _.reduce(config.features, function(memo, feature, name) {
      memo[name] = build(feature, false, bot, parentDisabled);
      if (_.isEmpty(memo[name])) {
        delete memo[name];
      }
      return memo;
    }, userConfig);
  }
};
