exports.collect = (arg, memo) ->
  memo.push(a) for a in arg.split(',')
  return memo
