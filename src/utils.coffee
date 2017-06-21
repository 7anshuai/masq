# The `util` module houses a number of utility functions used
# throughout Pow.

fs         = require "fs"
path       = require "path"
async      = require "async"
{execFile} = require "child_process"
{Stream}   = require "stream"


# A wrapper around `chown(8)` for taking ownership of a given path
# with the specified owner string (such as `"root:wheel"`). Invokes
# `callback` with the error string, if any, and a boolean value
# indicating whether or not the operation succeeded.
exports.chown = (path, owner, callback) ->
    error = ""
    exec ["chown", owner, path], (err, stdout, stderr) ->
        if err then callback err, stderr
        else callback null

# Spawn a Bash shell with the given `env` and source the named
# `script`. Then collect its resulting environment variables and pass
# them to `callback` as the second argument. If the script returns a
# non-zero exit code, call `callback` with the error as its first
# argument, and annotate the error with the captured `stdout` and
# `stderr`.
exports.sourceScriptEnv = (script, env, options, callback) ->
  if options.call
    callback = options
    options = {}
  else
    options ?= {}

  # Build up the command to execute, starting with the `before`
  # option, if any. Then source the given script, swallowing any
  # output written to stderr. Finally, dump the current environment to
  # a temporary file.
  cwd = path.dirname script
  filename = makeTemporaryFilename()
  command = """
    #{options.before ? "true"} &&
    source #{quote script} > /dev/null &&
    env > #{quote filename}
  """

  # Run our command through Bash in the directory of the script. If an
  # error occurs, rewrite the error to a more descriptive
  # message. Otherwise, read and parse the environment from the
  # temporary file and pass it along to the callback.
  exec ["bash", "-c", command], {cwd, env}, (err, stdout, stderr) ->
    if err
      err.message = "'#{script}' failed to load:\n#{command}"
      err.stdout = stdout
      err.stderr = stderr
      callback err
    else readAndUnlink filename, (err, result) ->
      if err then callback err
      else callback null, parseEnv result

# Get the user's login environment by spawning a login shell and
# collecting its environment variables via the `env` command. (In case
# the user's shell profile script prints output to stdout or stderr,
# we must redirect `env` output to a temporary file and read that.)
#
# The returned environment will include a default `LANG` variable if
# one is not set by the user's shell. This default value of `LANG` is
# determined by joining the user's current locale with the value of
# the `defaultEncoding` parameter, or `UTF-8` if it is not set.
exports.getUserEnv = (callback, defaultEncoding = "UTF-8") ->
  filename = makeTemporaryFilename()
  loginExec "exec env > #{quote filename}", (err) ->
    if err then callback err
    else readAndUnlink filename, (err, result) ->
      if err then callback err
      else getUserLocale (locale) ->
        env = parseEnv result
        env.LANG ?= "#{locale}.#{defaultEncoding}"
        callback null, env

# Execute a command without spawning a subshell. The command argument
# is an array of program name and arguments.
exec = (command, options, callback) ->
  unless callback?
    callback = options
    options = {}
  execFile "/usr/bin/env", command, options, callback

# Single-quote a string for command line execution.
quote = (string) -> "'" + string.replace(/\'/g, "'\\''") + "'"

# Generate and return a unique temporary filename based on the
# current process's PID, the number of milliseconds elapsed since the
# UNIX epoch, and a random integer.
makeTemporaryFilename = ->
  tmpdir    = process.env.TMPDIR ? "/tmp"
  timestamp = new Date().getTime()
  random    = parseInt Math.random() * Math.pow(2, 16)
  filename  = "pow.#{process.pid}.#{timestamp}.#{random}"
  path.join tmpdir, filename

# Read the contents of a file, unlink the file, then invoke the
# callback with the contents of the file.
readAndUnlink = (filename, callback) ->
  fs.readFile filename, "utf8", (err, contents) ->
    if err then callback err
    else fs.unlink filename, (err) ->
      if err then callback err
      else callback null, contents

# Execute the given command through a login shell and pass the
# contents of its stdout and stderr streams to the callback. In order
# to spawn a login shell, first spawn the user's shell with the `-l`
# option. If that fails, retry  without `-l`; some shells, like tcsh,
# cannot be started as non-interactive login shells. If that fails,
# bubble the error up to the callback.
loginExec = (command, callback) ->
  getUserShell (shell) ->
    login = ["login", "-qf", process.env.LOGNAME, shell]
    exec [login..., "-i", "-c", command], (err, stdout, stderr) ->
      if err
        exec [login..., "-c", command], callback
      else
        callback null, stdout, stderr

# Invoke `dscl(1)` to find out what shell the user prefers. We cannot
# rely on `process.env.SHELL` because it always seems to be
# `/bin/bash` when spawned from `launchctl`, regardless of what the
# user has set.
getUserShell = (callback) ->
  command = ["dscl", ".", "-read", "/Users/#{process.env.LOGNAME}", "UserShell"]
  exec command, (err, stdout, stderr) ->
    if err
      callback process.env.SHELL
    else
      if matches = stdout.trim().match /^UserShell: (.+)$/
        [match, shell] = matches
        callback shell
      else
        callback process.env.SHELL

# Read the user's current locale preference from the OS X defaults
# database. Fall back to `en_US` if it can't be determined.
getUserLocale = (callback) ->
  exec ["defaults", "read", "-g", "AppleLocale"], (err, stdout, stderr) ->
    locale = stdout?.trim() ? ""
    locale = "en_US" unless locale.match /^\w+$/
    callback locale

# Parse the output of the `env` command into a JavaScript object.
parseEnv = (stdout) ->
  env = {}
  for line in stdout.split "\n"
    if matches = line.match /([^=]+)=(.+)/
      [match, name, value] = matches
      env[name] = value
  env
