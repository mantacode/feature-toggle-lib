exports.collect = (arg, memo) ->
  if arg
    memo = memo || []
    memo.push(a) for a in arg.split(',')
    return memo
  else
    return true
