var flatten = require('flat');
var _ = require('lodash');

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

var unsort = exports.unsort = function(arr) {
  return _.reduce(arr, function(memo, item) {
    memo[ item.key ] = Number(item.val);
    return memo;
  }, {});
};

var getCode = exports.getCode = function(chunk) {
  var bin = parseInt(chunk.join(''), 2);
  return String.fromCharCode(bin + 64);
};

var getBin = exports.getBin = function(chr) {
  var code = chr.charCodeAt(0) - 64;
  return code.toString(2);
}

exports.pack = function(config) {
  var bits = _.map(sort(config), 'val');
  var chunks = _.chunk(bits, 5);
  return _.reduce(chunks, function(memo, chunk, i) {
    memo += getCode(chunk);
    if (i === chunks.length - 1) {
      memo += '|' + chunk.length;
    }
    return memo;
  }, '');
};

exports.unpack = function(str, config) {
  var sorted = sort(config);
  var parts = str.split('|');
  var letters = parts[0].split('');
  var bins = _.reduce(letters, function(memo, letter, i) {
    var bin = getBin(letter);
    if (i === letters.length - 1) {
      bin = _.padStart(bin, parts[1], '0');
    } else {
      bin = _.padStart(bin, 5, '0');
    }
    memo.push(bin);
    return memo;
  }, []).join('').split('');

  _.each(bins, function(bin, i) {
    sorted[i].val = bin; 
  });

  var unsorted = unsort(sorted);
  return flatten.unflatten(unsorted);
};
