var _ = typeof window !== 'undefined' && window._ ? window._ : require('lodash');

var mixins = {
  // Walks an object "obj" and calls "onPrimitive" whenever it encounters a primitive value or array (unless
  // "enterArrays" is true). If "enterArrays" is true, this function recurses into objects inside arrays as well.
  // "currentPath" and "origObj" are internal params passed when this function calls itself, so do not pass them
  // when you call it.
  recurse: function(obj, enterArrays, onPrimitive, currentPath, origObj) {
    if (typeof enterArrays === 'function') {
      onPrimitive = enterArrays;
      enterArrays = false;
    }

    // Loop over keys in object
    _.forOwn(obj, function(val, key) {
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
        _.each(val, function(innerObj, i) {
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

  flattenObject: function(obj) {
    var result = {};
    mixins.recurse(obj, true, function(path, val) {
      result[path] = val;
    });
    return result;
  },

  unflattenObject: function(obj) {
    return _(obj).keys().reduce(function(memo, k) {
      _.set(memo, k, obj[k]);
      return memo;
    }, {});
  }
};

_.mixin(mixins);

module.exports = _;
