var _ = require('lodash');
var math = require('./math');

var getTraffic = function(config, bot) {
  return typeof config.botTraffic !== 'undefined' && bot ? config.botTraffic : config.traffic;
};

var pickWinner = function(features, bot) {
  var floor = 0;
  var rand = math.random();
  return _.reduce(features, function(memo, feature, name) {
    var traffic = getTraffic(feature, bot);
    if (traffic) {
      var ceiling = floor + traffic;
      if (floor <= rand && ceiling > rand) {
        return name;
      } else {
        floor = ceiling;
        return memo;
      }
    }
  }, null);
};

var build = exports.build = function(config, alreadyPicked, bot) {
  if (!config) {
    return {};
  }

  var userConfig = {};
  if (config.version) {
    userConfig.v = config.version;
  }

  if ((typeof config.traffic !== 'undefined' && math.random() <= getTraffic(config, bot)) || alreadyPicked || config.version) {
    userConfig.e = 1;
  } else {
    return userConfig;
  }

  if (config.exclusiveSplit) {
    var pick = pickWinner(config.features, bot);
    if (pick) {
      userConfig[pick] = build(config.features[pick], true, bot);
    }
    return userConfig;
  } else {
    return _.reduce(config.features, function(memo, feature, name) {
      memo[name] = build(feature, false, bot) 
      if (_.isEmpty(memo[name])) {
        delete memo[name];
      }
      return memo;
    }, userConfig);
  }
};
