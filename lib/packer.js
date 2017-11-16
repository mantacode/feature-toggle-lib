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
  var unflat = flatten.unflatten(unsorted);
  unflat.v = Number(str.split('z')[0]);
  return unflat;
};
