cp = require 'child_process'
global.runCmd = (cmd, dir, done) ->
  args = cmd.split(' ')
  cp.spawn(args.shift(), args, { cwd: dir, stdio: 'inherit' }).on('close', done)
