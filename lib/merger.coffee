_ = require('underscore')

# doesn't handle arrays because we don't have any
merge = (a,b) ->
  if b?
    if typeof a == 'object' && not _(a).isArray()
      res = {}
      for k,v of a
        res[k] = merge(v, b[k])
      for k,v of b
        res[k] = v if not res[k]?
      return res
    else
      return b
  else
    return a

module.exports.merge = merge
