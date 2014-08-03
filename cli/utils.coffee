resolve = require 'resolve'
path = require 'path'
_ = require 'underscore'
async = require 'async'
fs = require 'fs'

exports.writeBlock = (msgs...) ->
  console.log()
  console.log '  ', msg for msg in msgs
  console.log()

exports.getFtoggleDir = ->
  pkg = resolve.sync 'feature-toggle-lib/package.json', { basedir: process.cwd() }
  return path.dirname(pkg)

exports.getRoot = ->
  ftoggleLib = @getFtoggleDir()
  return path.resolve(ftoggleLib, '..', '..')

exports.exit = (err) ->
  if err
    @writeBlock err
    process.exit(1)
  else
    process.exit(0)

exports.expand = (obj, path, val) ->
  parts = path.split('.')
  expandPath = parts.shift()

  while parts.length
    if !_(obj).safe(expandPath)
      _(obj).expand(expandPath, _.clone(val))
      
    expandPath += '.features.' + parts.shift()
  
  _(obj).expand(expandPath, val)

exports.bump = (args...) ->
  # Get the highest current version, in case they aren't all the same
  version = _.chain(@environments).map( (e) => @ftoggle[e].config.version ).max().value() + 1
  cb = args.pop()
  async.each @environments, (env, next) =>
    @ftoggle[env].config.version = version
    next()
  , (err) ->
    cb.apply null, [err].concat(args)

exports.write = (args...) ->
  cb = args.pop()
  root = exports.getRoot()
  async.each @environments, (env, next) =>
    # Remove all .. parts in the path, since config locations are relative to the root already
    file = _(@ftoggle[env].path.split('/')).reject( (part) -> return part == '..').join('/')
    fs.writeFile "#{root}/#{file}", JSON.stringify(@ftoggle[env].config), next
  , (err) ->
    cb.apply null, [err].concat(args)

