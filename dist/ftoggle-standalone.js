(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.Ftoggle = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var _ = typeof window !== 'undefined' && window._ ? window._ : require('lodash');
var packer = require('./packer');

var Ftoggle = module.exports = function(config, featureVals, toggleConfig) {
  this.config = config;
  this.toggleConfig = toggleConfig || {};
  this.featureVals = featureVals || {};
};

Ftoggle.prototype.isFeatureEnabled = function(feature) {
  return Boolean(_.get(this.config, feature + '.e'));
};

Ftoggle.prototype.findEnabledChildren = function(parent) {
  var subset = parent ? _.get(this.config, parent) : this.config;
  return _(subset).keys().without('e', 'v').filter(function(k) {
    return subset[k].e;
  }).value()
};

Ftoggle.prototype.doesFeatureExist = function(feature) {
  return _.has(this.toggleConfig, this.makeFeaturePath(feature));
};

Ftoggle.prototype.getFeatures = function() {
  return this.config;
};

Ftoggle.prototype.featureVal = function(key) {
  return this.featureVals[key] || null;
};

Ftoggle.prototype.getFeatureVals = function() {
  return this.featureVals;
};

Ftoggle.prototype.getConfigForFeature = function(feature) {
  return _.get(this.toggleConfig, feature + '.conf');
};

Ftoggle.prototype.setFeatures = function(feature) {
  var featureConf = this.getConfigForFeature(feature);
  _.each(featureConf, function(value, key) {
    this.featureVals[key] = value;
  }.bind(this));
  return this;
};

Ftoggle.prototype.unsetFeatures = function(feature) {
  var featureConf = this.getConfigForFeature(feature);
  _.each(featureConf, function(value, key) {
    delete this.featureVals[key];
  }.bind(this));
  return this;
};

Ftoggle.prototype.enable = function(feature) {
  var featurePath = this.makeFeaturePath(feature);
  if (_.has(this.toggleConfig, featurePath)) {
    var parts = feature.split('.');
    var current = '';
    while (parts.length > 0) {
      current += (current ? '.' : '') + parts.shift();
      var innerFeaturePath = this.makeFeaturePath(current);
      var currentConfig = _.get(this.toggleConfig, innerFeaturePath);
      if (currentConfig && currentConfig.exclusiveSplit) {
        this.unsetAll(_.get(this.config, current));
        _.each(currentConfig.features, function(value, key) {
          this.unsetFeatures(innerFeaturePath + '.features.' + key);
        }.bind(this));
      }

      _.set(this.config, current + '.e', 1);
      this.setFeatures(innerFeaturePath);
    }
  }
  return this;
};

Ftoggle.prototype.enableAll = function(features) {
  if (!_.isArray(features)) {
    features = features.split(',');
  }
  
  _.each(features, this.enable.bind(this));
};

Ftoggle.prototype.disable = function(feature) {
  var featurePath = this.makeFeaturePath(feature);
  if (_.has(this.toggleConfig, featurePath)) {
    this.unsetAll(_.get(this.config, feature));
    this.unsetFeatures(featurePath);
    _.each(this.getAllChildNodes(this.toggleConfig, featurePath), function(node) {
      this.unsetFeatures(node);
    }.bind(this));
  }
  return this;
};

Ftoggle.prototype.disableAll = function(features) {
  if (!_.isArray(features)) {
    features = features.split(',');
  }

  _.each(features, this.disable.bind(this));
};

Ftoggle.prototype.toggleName = function() {
  return 'ftoggle-' + this.toggleConfig.name;
};

Ftoggle.prototype.makeFeaturePath = function(feature) {
  return 'features.' + feature.split('.').join('.features.');
};

Ftoggle.prototype.getAllChildNodes = function(config, path) {
  var thisConfig = _.get(config, path + '.features');
  return _.reduce(thisConfig, function(memo, val, key) {
    var inner = path + '.features.' + key;
    memo.push(inner);
    _.each(this.getAllChildNodes(thisConfig, key), function(child) {
      memo.push(path + '.features.' + child);
    });
    return memo;
  }.bind(this), []);
};

Ftoggle.prototype.unsetAll = function(config) {
  config.e = 0;
  _.each(config, function(val, key) {
    if (key !== 'e') {
      this.unsetAll(config[key]);
    }
  }.bind(this));
};

Ftoggle.prototype.getPackedConfig = function() {
  return packer.pack(this.config);
};

Ftoggle.getUnpackedConfig = function(cookie, conf) {
  return packer.unpack(cookie, conf);
};

},{"./packer":2,"lodash":undefined}],2:[function(require,module,exports){
var flatten = require('flat');
var _ = typeof window !== 'undefined' && window._ ? window._ : require('lodash');

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
var sort = exports.sort = function(obj) {
  // Flatten the object (get all nested keys as top level, dot delimited keys),
  // remove the "v" key, which represents the version, and then transform the
  // resulting object into an array of objects. Finally, sort the array by the
  // key name so we have a reliable order of values.
  return _.chain(flatten(obj)).omit('v').reduce(function(memo, val, key) {
    memo.push({
      key: key,
      val: val
    });
    return memo;
  }, []).sortBy('key').value();
};

// Basically the reverse of the above, except that sorting doesn't matter
// since key order isnt' guaranteed.
var construct = exports.construct = function(arr) {
  return _.reduce(arr, function(memo, item) {
    memo[ item.key ] = Number(item.val);
    return memo;
  }, {});
};

// Convert 1 to 5 digits to printable character (between
// 64 and 95).
var getCode = exports.getCode = function(chunk) {
  // Parse a chunk of 1 to 5 digits into binary.
  var bin = parseInt(chunk.join(''), 2);
  // Return the char code, shifted up by 64. This places the final
  // value between 64 and 95, which is basically the capital letter
  // range, plus a few symbols on each end.
  return String.fromCharCode(bin + 64);
};

// Reverse the above. Convert a character back to a binary representation.
var getBin = exports.getBin = function(chr) {
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
var getVals = exports.getVals = function(parts) {
  // parts 0 is the encoding and parts 1 is the number of significant digits
  // in the final character.
  var letters = parts[0].split(''); 
  return _.reduce(letters, function(memo, letter, i) {
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
exports.pack = function(config) {
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
  return _.reduce(chunks, function(memo, chunk, i) {
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
exports.unpack = function(str, config) {
  // Get an array of 1s and 0s from the string
  var bits = getVals(str.split('z').slice(1));

  // Get the actual config object we're working with. Doesn't matter what values
  // the config has, as long as it has all the right keys.
  var sorted = sort(config);

  // Iterate over the bits
  _.each(bits, function(bit, i) {
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
  var flat = flatten.unflatten(unsorted);
  flat.v = Number(str.split('z')[0]);
  return flat;
};

},{"flat":3,"lodash":undefined}],3:[function(require,module,exports){
var isBuffer = require('is-buffer')

var flat = module.exports = flatten
flatten.flatten = flatten
flatten.unflatten = unflatten

function flatten(target, opts) {
  opts = opts || {}

  var delimiter = opts.delimiter || '.'
  var maxDepth = opts.maxDepth
  var output = {}

  function step(object, prev, currentDepth) {
    currentDepth = currentDepth ? currentDepth : 1
    Object.keys(object).forEach(function(key) {
      var value = object[key]
      var isarray = opts.safe && Array.isArray(value)
      var type = Object.prototype.toString.call(value)
      var isbuffer = isBuffer(value)
      var isobject = (
        type === "[object Object]" ||
        type === "[object Array]"
      )

      var newKey = prev
        ? prev + delimiter + key
        : key

      if (!isarray && !isbuffer && isobject && Object.keys(value).length &&
        (!opts.maxDepth || currentDepth < maxDepth)) {
        return step(value, newKey, currentDepth + 1)
      }

      output[newKey] = value
    })
  }

  step(target)

  return output
}

function unflatten(target, opts) {
  opts = opts || {}

  var delimiter = opts.delimiter || '.'
  var overwrite = opts.overwrite || false
  var result = {}

  var isbuffer = isBuffer(target)
  if (isbuffer || Object.prototype.toString.call(target) !== '[object Object]') {
    return target
  }

  // safely ensure that the key is
  // an integer.
  function getkey(key) {
    var parsedKey = Number(key)

    return (
      isNaN(parsedKey) ||
      key.indexOf('.') !== -1
    ) ? key
      : parsedKey
  }

  Object.keys(target).forEach(function(key) {
    var split = key.split(delimiter)
    var key1 = getkey(split.shift())
    var key2 = getkey(split[0])
    var recipient = result

    while (key2 !== undefined) {
      var type = Object.prototype.toString.call(recipient[key1])
      var isobject = (
        type === "[object Object]" ||
        type === "[object Array]"
      )

      // do not write over falsey, non-undefined values if overwrite is false
      if (!overwrite && !isobject && typeof recipient[key1] !== 'undefined') {
        return
      }

      if ((overwrite && !isobject) || (!overwrite && recipient[key1] == null)) {
        recipient[key1] = (
          typeof key2 === 'number' &&
          !opts.object ? [] : {}
        )
      }

      recipient = recipient[key1]
      if (split.length > 0) {
        key1 = getkey(split.shift())
        key2 = getkey(split[0])
      }
    }

    // unflatten again for 'messy objects'
    recipient[key1] = unflatten(target[key], opts)
  })

  return result
}

},{"is-buffer":4}],4:[function(require,module,exports){
/*!
 * Determine if an object is a Buffer
 *
 * @author   Feross Aboukhadijeh <feross@feross.org> <http://feross.org>
 * @license  MIT
 */

// The _isBuffer check is for Safari 5-7 support, because it's missing
// Object.prototype.constructor. Remove this eventually
module.exports = function (obj) {
  return obj != null && (isBuffer(obj) || isSlowBuffer(obj) || !!obj._isBuffer)
}

function isBuffer (obj) {
  return !!obj.constructor && typeof obj.constructor.isBuffer === 'function' && obj.constructor.isBuffer(obj)
}

// For Node v0.10 support. Remove this eventually.
function isSlowBuffer (obj) {
  return typeof obj.readFloatLE === 'function' && typeof obj.slice === 'function' && isBuffer(obj.slice(0, 0))
}

},{}]},{},[1])(1)
});