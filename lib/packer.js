var flatten = require('flat');
var _ = require('lodash');

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
  var flatObj = flatten(obj);
  return _.chain(flatten(obj)).reduce(function(memo, val, key) {
    memo.push({
      key: key,
      val: val
    });
    return memo;
  }, []).sortBy('key').value();
};

// Basically the reverse of the above, except that sorting doesn't matter
// since key ordered isnt' guaranteed.
var construct = exports.construct = function(arr) {
  return _.reduce(arr, function(memo, item) {
    memo[ item.key ] = Number(item.val);
    return memo;
  }, {});
};

// Convert 1 to 5 digits to printable character (between
// 64 and 95).
var getCode = exports.getCode = function(chunk) {
  var bin = parseInt(chunk.join(''), 2);
  return String.fromCharCode(bin + 64);
};

var getBin = exports.getBin = function(chr) {
  chr = revmap[chr] ? revmap[chr] : chr;
  var code = chr.charCodeAt(0) - 64;
  return code.toString(2);
};

var getVals = exports.getVals = function(str) {
  var parts = str.split('z');
  var letters = parts[0].split(''); 
  return _.reduce(letters, function(memo, letter, i) {
    var bin = getBin(letter);
    if (i === letters.length - 1) {
      bin = _.padStart(bin, parts[1], '0');
    } else {
      bin = _.padStart(bin, 5, '0');
    }
    memo.push(bin);
    return memo;
  }, []).join('').split('');
};

exports.pack = function(config) {
  var bits = _.map(sort(config), 'val');
  var chunks = _.chunk(bits, 5);
  return _.reduce(chunks, function(memo, chunk, i) {
    var letter = getCode(chunk);
    if (map[letter]) {
      memo += map[letter];
    } else {
      memo += letter;
    }
    if (i === chunks.length - 1) {
      memo += 'z' + chunk.length;
    }
    return memo;
  }, '');
};

exports.unpack = function(str, config) {
  var bins = getVals(str);

  var sorted = sort(config);
  _.each(bins, function(bin, i) {
    sorted[i].val = bin; 
  });

  var unsorted = construct(sorted);
  return flatten.unflatten(unsorted);
};
