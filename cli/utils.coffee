resolve = require 'resolve'
path = require 'path'
_ = require 'underscore'
async = require 'async'
fs = require 'fs'
cp = require 'child_process'
chalk = require 'chalk'
readline = require 'readline'
rl = null

exports.getInterface = ->
  rl = rl or readline.createInterface({ input: process.stdin, output: process.stdout })
  return rl

exports.closeInterface = ->
  rl?.close()

exports.writeBlock = (msgs...) ->
  console.log()
  console.log '  ', msg for msg in msgs
  console.log()

exports.getFtoggleDir = ->
  try
    pkg = resolve.sync 'ftoggle/package.json', { basedir: process.cwd() }
    return path.dirname(pkg)
  catch e
    exports.writeBlock chalk.red('Unable to locate local ftoggle installation.'), "Run #{chalk.gray('npm install ftoggle --save')} followed by #{chalk.gray('ftoggle init')} to get started."
    exports.exit()

exports.getRoot = ->
  ftoggleLib = @getFtoggleDir()
  return path.resolve(ftoggleLib, '..', '..')

exports.fromRoot = (p) ->
  # slice(0, -1) removes the trailing slash from the path, so that the returned path is predictable
  return path.normalize("#{exports.getRoot()}/#{p}/").slice(0, -1)

exports.exit = (err) ->
  if err
    exports.writeBlock err
    process.exit 1
  else
    process.exit 0

exports.expand = (obj, path, val) ->
  parts = path.split('.')
  expandPath = parts.shift()
  #if @splitPlan == 'prompt'
    #rl = exports.getInterface()

  while parts.length
    if !_(obj).safe(expandPath)
      _(obj).expand(expandPath, _.clone(val))
      
    expandPath += '.features.' + parts.shift()
  
  _(obj).expand(expandPath, val)

exports.bump = (args..., env, cb) ->
  # Get the highest current version, in case they aren't all the same
  @ftoggleVersion = @ftoggleVersion || _.chain(@ftoggle.environments).map( (e) => @ftoggle[e].version ).max().value() + 1
  @ftoggle[env].version = @ftoggleVersion
  @modified.push(env)
  cb.apply null, [null].concat(args).concat(env)

exports.write = (args..., env, cb) ->
  conf = exports.fromRoot(@ftoggle.configDir)
  fs.writeFile "#{conf}/ftoggle.#{env}.json", JSON.stringify(@ftoggle[env], null, 2), (err) ->
    cb.apply null, [err].concat(args).concat(env)

exports.stage = (args..., cb) ->
  conf = exports.fromRoot(@ftoggle.configDir)
  files = if _(@stage).isArray() then _(@stage).map( (env) => "#{conf}/ftoggle.#{env}.json" ) else ["#{conf}/*"]
  add = cp.spawn 'git', ['add'].concat(files)
  add.on 'close', (code) =>
    cb.apply null, [if code then exports.failedCmdMessage("git add #{files.join(' ')}", code) else null].concat(args)

exports.commit = (args..., cb) ->
  commit = cp.spawn 'git', ['commit', '-m', @commitMsg]
  commit.on 'close', (code) =>
    cb.apply null, [if code then exports.failedCmdMessage("git commit -m '#{@commitMsg}'", code) else null].concat(args)

exports.failedCmdMessage = (cmd, code) ->
  return "#{chalk.gray(cmd)} returned code #{chalk.red(code)}"
