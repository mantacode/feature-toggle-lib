(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.Ftoggle = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var _ = require('./lodash');
var packer = require('./packer');

var Ftoggle = function () {
  function Ftoggle(config, featureVals, toggleConfig) {
    _classCallCheck(this, Ftoggle);

    this.config = config;
    this.toggleConfig = toggleConfig || {};
    this.featureVals = featureVals || {};
  }

  _createClass(Ftoggle, [{
    key: 'isFeatureEnabled',
    value: function isFeatureEnabled(feature) {
      return Boolean(_.get(this.config, feature + '.e'));
    }
  }, {
    key: 'findEnabledChildren',
    value: function findEnabledChildren(parent) {
      var subset = parent ? _.get(this.config, parent) : this.config;
      return _(subset).keys().without('e', 'v').filter(function (k) {
        return subset[k].e;
      }).value();
    }
  }, {
    key: 'doesFeatureExist',
    value: function doesFeatureExist(feature) {
      return _.has(this.toggleConfig, this.makeFeaturePath(feature));
    }
  }, {
    key: 'getFeatures',
    value: function getFeatures() {
      return this.config;
    }
  }, {
    key: 'featureVal',
    value: function featureVal(key) {
      return this.featureVals[key] || null;
    }
  }, {
    key: 'getFeatureVals',
    value: function getFeatureVals() {
      return this.featureVals;
    }
  }, {
    key: 'getConfigForFeature',
    value: function getConfigForFeature(feature) {
      return _.get(this.toggleConfig, feature + '.conf');
    }
  }, {
    key: 'setFeatures',
    value: function setFeatures(feature) {
      var _this = this;

      var featureConf = this.getConfigForFeature(feature);
      _.each(featureConf, function (value, key) {
        _this.featureVals[key] = value;
      });
      return this;
    }
  }, {
    key: 'unsetFeatures',
    value: function unsetFeatures(feature) {
      var _this2 = this;

      var featureConf = this.getConfigForFeature(feature);
      _.each(featureConf, function (value, key) {
        delete _this2.featureVals[key];
      });
      return this;
    }
  }, {
    key: 'enable',
    value: function enable(feature) {
      var _this3 = this;

      var featurePath = this.makeFeaturePath(feature);
      if (_.has(this.toggleConfig, featurePath)) {
        var parts = feature.split('.');
        var current = '';
        var unset = function unset(innerFeaturePath) {
          return function (value, key) {
            _this3.unsetFeatures(innerFeaturePath + '.features.' + key);
          };
        };
        while (parts.length > 0) {
          current += (current ? '.' : '') + parts.shift();
          var innerFeaturePath = this.makeFeaturePath(current);
          var currentConfig = _.get(this.toggleConfig, innerFeaturePath);
          if (currentConfig && currentConfig.exclusiveSplit) {
            this.unsetAll(_.get(this.config, current));
            _.each(currentConfig.features, unset(innerFeaturePath));
          }

          _.set(this.config, current + '.e', 1);
          this.setFeatures(innerFeaturePath);
        }
      }
      return this;
    }
  }, {
    key: 'enableAll',
    value: function enableAll(features) {
      if (!_.isArray(features)) {
        features = features.split(',');
      }

      _.each(features, this.enable.bind(this));
    }
  }, {
    key: 'disable',
    value: function disable(feature) {
      var _this4 = this;

      var featurePath = this.makeFeaturePath(feature);
      if (_.has(this.toggleConfig, featurePath)) {
        this.unsetAll(_.get(this.config, feature));
        this.unsetFeatures(featurePath);
        _.each(this.getAllChildNodes(this.toggleConfig, featurePath), function (node) {
          _this4.unsetFeatures(node);
        });
      }
      return this;
    }
  }, {
    key: 'disableAll',
    value: function disableAll(features) {
      if (!_.isArray(features)) {
        features = features.split(',');
      }

      _.each(features, this.disable.bind(this));
    }
  }, {
    key: 'toggleName',
    value: function toggleName() {
      return 'ftoggle-' + this.toggleConfig.name;
    }
  }, {
    key: 'makeFeaturePath',
    value: function makeFeaturePath(feature) {
      return 'features.' + feature.split('.').join('.features.');
    }
  }, {
    key: 'getAllChildNodes',
    value: function getAllChildNodes(config, path) {
      var _this5 = this;

      var thisConfig = _.get(config, path + '.features');
      return _.reduce(thisConfig, function (memo, val, key) {
        var inner = path + '.features.' + key;
        memo.push(inner);
        _.each(_this5.getAllChildNodes(thisConfig, key), function (child) {
          memo.push(path + '.features.' + child);
        });
        return memo;
      }, []);
    }
  }, {
    key: 'unsetAll',
    value: function unsetAll(config) {
      var _this6 = this;

      config.e = 0;
      _.each(config, function (val, key) {
        if (key !== 'e') {
          _this6.unsetAll(config[key]);
        }
      });
    }
  }, {
    key: 'getPackedConfig',
    value: function getPackedConfig() {
      return packer.pack(this.config);
    }

    // Not a typo. This is not on prototype because
    // you need this function to generate the config
    // that is required to create an instance of Ftoggle.

  }], [{
    key: 'getUnpackedConfig',
    value: function getUnpackedConfig(cookie, conf) {
      return packer.unpack(cookie, conf);
    }
  }]);

  return Ftoggle;
}();

module.exports = Ftoggle;

},{"./lodash":2,"./packer":3}],2:[function(require,module,exports){
'use strict';

var _ = typeof window !== 'undefined' && window._ ? window._ : require('lodash');

var mixins = {
  // Walks an object "obj" and calls "onPrimitive" whenever it encounters a primitive value or array (unless
  // "enterArrays" is true). If "enterArrays" is true, this function recurses into objects inside arrays as well.
  // "currentPath" and "origObj" are internal params passed when this function calls itself, so do not pass them
  // when you call it.
  recurse: function recurse(obj, enterArrays, onPrimitive, currentPath, origObj) {
    if (typeof enterArrays === 'function') {
      onPrimitive = enterArrays;
      enterArrays = false;
    }

    // Loop over keys in object
    _.forOwn(obj, function (val, key) {
      // Set the path at this point in the object. If this is the top level of the object, use just the key.
      // Otherwise, add the key to any previously generated path (from a highler level).
      var path = currentPath ? currentPath + '.' + key : key;
      // If this property is an object, recurse into it
      if (_.isPlainObject(val)) {
        // Pass in the current path and object. Since "obj" changes on iterations (to nested object), we
        // need to preserve the original top level object so that it can be passed to "onPrimitive" below.
        mixins.recurse(val, enterArrays, onPrimitive, path, origObj || obj);
      } else if (_.isArray(val) && enterArrays) {
        // If "enterArrays" is true, loop through the array
        _.each(val, function (innerObj, i) {
          // Add the array index to the path
          var innerPath = path + '.' + i;
          if (_.isArray(innerObj) || _.isPlainObject(innerObj)) {
            // If the inner property is an object or array, recurse into it
            mixins.recurse(innerObj, enterArrays, onPrimitive, innerPath, origObj || obj);
          } else {
            // Otherwise, call onPrimitive
            onPrimitive(innerPath, innerObj, origObj || obj);
          }
        });
      } else {
        // Call on primitive with full path to this property, the property itself, and the original object
        onPrimitive(path, val, origObj || obj);
      }
    });
  },

  flattenObject: function flattenObject(obj) {
    var result = {};
    mixins.recurse(obj, true, function (path, val) {
      result[path] = val;
    });
    return result;
  },

  unflattenObject: function unflattenObject(obj) {
    return _(obj).keys().reduce(function (memo, k) {
      _.set(memo, k, obj[k]);
      return memo;
    }, {});
  }
};

_.mixin(mixins);

module.exports = _;

},{"lodash":undefined}],3:[function(require,module,exports){
'use strict';

var _ = require('./lodash');

// There are only 5 characters in the spectrum of used characters that get
// encoded by encodeURIComponent. For space and to not have to call
// decodeURIComponent, I'm just mapping those 5 characters to the first 5
// lower case letters, which are unused in this algorithm.
var map = {
  '@': 'a',
  '[': 'b',
  '\\': 'c',
  ']': 'd',
  '^': 'e'
};

// Back map for decoding.
var revmap = {
  a: '@',
  b: '[',
  c: '\\',
  d: ']',
  e: '^'
};

// Takes a regular object, flattens it, deconstructs it into
// an array of objects with key and val, and sorts on key.
// E.g.
//  {
//    foo: {
//      banana: 1,
//      apple: 0
//    }
//  }
//  results in
//  [
//    {
//      key: 'foo.apple',
//      val: 0
//    },
//    {
//      key: 'foo.banana',
//      val: 1
//    }
//  ]
var sort = exports.sort = function (obj) {
  // Flatten the object (get all nested keys as top level, dot delimited keys),
  // remove the "v" key, which represents the version, and then transform the
  // resulting object into an array of objects. Finally, sort the array by the
  // key name so we have a reliable order of values.
  return _.chain(obj).flattenObject().omit('v').reduce(function (memo, val, key) {
    return memo.concat({
      key: key,
      val: val
    });
  }, []).sortBy('key').value();
};

// Basically the reverse of the above, except that sorting doesn't matter
// since key order isnt' guaranteed.
var construct = exports.construct = function (arr) {
  return _.reduce(arr, function (memo, item) {
    memo[item.key] = Number(item.val);
    return memo;
  }, {});
};

// Convert 1 to 5 digits to printable character (between
// 64 and 95).
var getCode = exports.getCode = function (chunk) {
  // Parse a chunk of 1 to 5 digits into binary.
  var bin = parseInt(chunk.join(''), 2);
  // Return the char code, shifted up by 64. This places the final
  // value between 64 and 95, which is basically the capital letter
  // range, plus a few symbols on each end.
  return String.fromCharCode(bin + 64);
};

// Reverse the above. Convert a character back to a binary representation.
var getBin = exports.getBin = function (chr) {
  // If this is a mapped char, use that char instead of the actual char.
  chr = revmap[chr] ? revmap[chr] : chr;
  // Get the charcode and shift down by 64
  var code = chr.charCodeAt(0) - 64;
  // Return the binary representation of that code
  return code.toString(2);
};

// Could probably be called "getBins" but that seemed too close to the method
// above. This converts a series of characters to binary representations,
// returning a single string of 1s and 0s.
var getVals = exports.getVals = function (parts) {
  // parts 0 is the encoding and parts 1 is the number of significant digits
  // in the final character.
  var letters = parts[0].split('');
  return _.reduce(letters, function (memo, letter, i) {
    // Get the binary representation of the letter
    var bin = getBin(letter);
    if (i === letters.length - 1) {
      // If this is the final letter, left pad only to the number
      // of significant digits. This prevents generating extra "false"
      // flags toward the end of the config.
      bin = _.padStart(bin, parts[1], '0');
    } else {
      // If it's not the end, left pad with 0s, up to 5 spaces, since
      // something like "00001" comes back as just "1"
      bin = _.padStart(bin, 5, '0');
    }
    memo.push(bin);
    return memo;
  }, [])
  // Join, e.g., ['11111', '00000', '10101'] into a single string and then split
  // back into an array of individual characters
  .join('').split('');
};

// Convert a config object into a series of 1 and 0 flags. Format of the return
// value is [version]z[config representation]z[number of significant digits in last letter]
exports.pack = function (config) {
  // Sort the config and pluck out the vals
  var bits = _.map(sort(config), 'val');
  // Separate into chunks of 5. This helps ensure that all the characters fall in the
  // printable character range. Other combinations are possible, for instance, chunking
  // in 6s and shifting by 32 instead of 64 gives you all printable characters as well,
  // but many more of them are symbols that require encoding, so while you'd only gain
  // MAYBE a couple digits in your packed representation, you'd actually lose more
  // either in length once encoded or in complexity by having a much larger key map
  // (like the one at the top). Chunks of 5 shifted by 64 seems sufficient.
  var chunks = _.chunk(bits, 5);
  return _.reduce(chunks, function (memo, chunk, i) {
    // Get the letter representation of this chunk
    var letter = getCode(chunk);
    // If there's a mapping for this letter, use that instead of the actual letter
    memo += map[letter] || letter;
    // If this is the last chunk, also append the number of digits in the chunk.
    // _.chunk(list, 5) will give you chunks of 5, but if there's an odd number
    // the final chunk will be the remainder. We need to know (e.g.) that there
    // are only 3 digits in this chunk, otherwise we'll unpack it incorrectly.
    if (i === chunks.length - 1) {
      // 'z' is just a divider since it is unused in the packing algorithm
      memo += 'z' + chunk.length;
    }
    return memo;
  }, config.v + 'z'); // Starting value is version + 'z'
};

// Reverse the above. Convert something like 2zYA_z5 to a configuration object.
exports.unpack = function (str, config) {
  // Get an array of 1s and 0s from the string
  var bits = getVals(str.split('z').slice(1));

  // Get the actual config object we're working with. Doesn't matter what values
  // the config has, as long as it has all the right keys.
  var sorted = sort(config);

  // Iterate over the bits
  _.each(bits, function (bit, i) {
    // Safety check in case (for example) we forget to bump ftoggle
    // and make changes that cause the number of keys to be different
    if (sorted[i]) {
      // Assign the value of this toggle based on the cookied bit
      sorted[i].val = bit;
    }
  });

  // Put our config array back into an object
  var unsorted = construct(sorted);
  // And return an unflattened version
  var unflat = _.unflattenObject(unsorted);
  unflat.v = Number(str.split('z')[0]);
  return unflat;
};

},{"./lodash":2}]},{},[1])(1)
});