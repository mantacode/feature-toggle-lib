exports.writeLine = (msg) ->
  console.log '  ', msg

exports.writeLines = (msgs...) ->
  console.log()
  console.log '  ', msg for msg in msgs
  console.log()
