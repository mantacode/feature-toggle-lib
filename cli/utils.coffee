resolve = require 'resolve'
path = require 'path'

exports.writeBlock = (msgs...) ->
  console.log()
  console.log '  ', msg for msg in msgs
  console.log()

exports.getRoot = ->
  resolved = resolve.sync 'feature-toggle-lib/package.json', { basedir: process.cwd() }
  return path.resolve(path.dirname(resolved), '..', '..')

exports.exit = (err) ->
  if err
    @writeBlock err
    process.exit(1)
  else
    process.exit(0)
