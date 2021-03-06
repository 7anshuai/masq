// Generated by CoffeeScript 2.0.0
(function() {
  // The `util` module houses a number of utility functions used
  // throughout Pow.
  var Stream, async, exec, execFile, fs, getUserLocale, getUserShell, loginExec, makeTemporaryFilename, parseEnv, path, quote, readAndUnlink;

  fs = require("fs");

  path = require("path");

  async = require("async");

  ({execFile} = require("child_process"));

  ({Stream} = require("stream"));

  // A wrapper around `chown(8)` for taking ownership of a given path
  // with the specified owner string (such as `"root:wheel"`). Invokes
  // `callback` with the error string, if any, and a boolean value
  // indicating whether or not the operation succeeded.
  exports.chown = function(path, owner, callback) {
    var error;
    error = "";
    return exec(["chown", owner, path], function(err, stdout, stderr) {
      if (err) {
        return callback(err, stderr);
      } else {
        return callback(null);
      }
    });
  };

  // Spawn a Bash shell with the given `env` and source the named
  // `script`. Then collect its resulting environment variables and pass
  // them to `callback` as the second argument. If the script returns a
  // non-zero exit code, call `callback` with the error as its first
  // argument, and annotate the error with the captured `stdout` and
  // `stderr`.
  exports.sourceScriptEnv = function(script, env, options, callback) {
    var command, cwd, filename, ref;
    if (options.call) {
      callback = options;
      options = {};
    } else {
      if (options == null) {
        options = {};
      }
    }
    // Build up the command to execute, starting with the `before`
    // option, if any. Then source the given script, swallowing any
    // output written to stderr. Finally, dump the current environment to
    // a temporary file.
    cwd = path.dirname(script);
    filename = makeTemporaryFilename();
    command = `${(ref = options.before) != null ? ref : "true"} &&\nsource ${quote(script)} > /dev/null &&\nenv > ${quote(filename)}`;
    // Run our command through Bash in the directory of the script. If an
    // error occurs, rewrite the error to a more descriptive
    // message. Otherwise, read and parse the environment from the
    // temporary file and pass it along to the callback.
    return exec(["bash", "-c", command], {cwd, env}, function(err, stdout, stderr) {
      if (err) {
        err.message = `'${script}' failed to load:\n${command}`;
        err.stdout = stdout;
        err.stderr = stderr;
        return callback(err);
      } else {
        return readAndUnlink(filename, function(err, result) {
          if (err) {
            return callback(err);
          } else {
            return callback(null, parseEnv(result));
          }
        });
      }
    });
  };

  // Get the user's login environment by spawning a login shell and
  // collecting its environment variables via the `env` command. (In case
  // the user's shell profile script prints output to stdout or stderr,
  // we must redirect `env` output to a temporary file and read that.)

  // The returned environment will include a default `LANG` variable if
  // one is not set by the user's shell. This default value of `LANG` is
  // determined by joining the user's current locale with the value of
  // the `defaultEncoding` parameter, or `UTF-8` if it is not set.
  exports.getUserEnv = function(callback, defaultEncoding = "UTF-8") {
    var filename;
    filename = makeTemporaryFilename();
    return loginExec(`exec env > ${quote(filename)}`, function(err) {
      if (err) {
        return callback(err);
      } else {
        return readAndUnlink(filename, function(err, result) {
          if (err) {
            return callback(err);
          } else {
            return getUserLocale(function(locale) {
              var env;
              env = parseEnv(result);
              if (env.LANG == null) {
                env.LANG = `${locale}.${defaultEncoding}`;
              }
              return callback(null, env);
            });
          }
        });
      }
    });
  };

  // Execute a command without spawning a subshell. The command argument
  // is an array of program name and arguments.
  exec = function(command, options, callback) {
    if (callback == null) {
      callback = options;
      options = {};
    }
    return execFile("/usr/bin/env", command, options, callback);
  };

  // Single-quote a string for command line execution.
  quote = function(string) {
    return "'" + string.replace(/\'/g, "'\\''") + "'";
  };

  // Generate and return a unique temporary filename based on the
  // current process's PID, the number of milliseconds elapsed since the
  // UNIX epoch, and a random integer.
  makeTemporaryFilename = function() {
    var filename, random, ref, timestamp, tmpdir;
    tmpdir = (ref = process.env.TMPDIR) != null ? ref : "/tmp";
    timestamp = new Date().getTime();
    random = parseInt(Math.random() * Math.pow(2, 16));
    filename = `masq.${process.pid}.${timestamp}.${random}`;
    return path.join(tmpdir, filename);
  };

  // Read the contents of a file, unlink the file, then invoke the
  // callback with the contents of the file.
  readAndUnlink = function(filename, callback) {
    return fs.readFile(filename, "utf8", function(err, contents) {
      if (err) {
        return callback(err);
      } else {
        return fs.unlink(filename, function(err) {
          if (err) {
            return callback(err);
          } else {
            return callback(null, contents);
          }
        });
      }
    });
  };

  // Execute the given command through a login shell and pass the
  // contents of its stdout and stderr streams to the callback. In order
  // to spawn a login shell, first spawn the user's shell with the `-l`
  // option. If that fails, retry  without `-l`; some shells, like tcsh,
  // cannot be started as non-interactive login shells. If that fails,
  // bubble the error up to the callback.
  loginExec = function(command, callback) {
    return getUserShell(function(shell) {
      var login;
      login = ["login", "-qf", process.env.LOGNAME, shell];
      return exec([...login, "-i", "-c", command], function(err, stdout, stderr) {
        if (err) {
          return exec([...login, "-c", command], callback);
        } else {
          return callback(null, stdout, stderr);
        }
      });
    });
  };

  // Invoke `dscl(1)` to find out what shell the user prefers. We cannot
  // rely on `process.env.SHELL` because it always seems to be
  // `/bin/bash` when spawned from `launchctl`, regardless of what the
  // user has set.
  getUserShell = function(callback) {
    var command;
    command = ["dscl", ".", "-read", `/Users/${process.env.LOGNAME}`, "UserShell"];
    return exec(command, function(err, stdout, stderr) {
      var match, matches, shell;
      if (err) {
        return callback(process.env.SHELL);
      } else {
        if (matches = stdout.trim().match(/^UserShell: (.+)$/)) {
          [match, shell] = matches;
          return callback(shell);
        } else {
          return callback(process.env.SHELL);
        }
      }
    });
  };

  // Read the user's current locale preference from the OS X defaults
  // database. Fall back to `en_US` if it can't be determined.
  getUserLocale = function(callback) {
    return exec(["defaults", "read", "-g", "AppleLocale"], function(err, stdout, stderr) {
      var locale, ref;
      locale = (ref = stdout != null ? stdout.trim() : void 0) != null ? ref : "";
      if (!locale.match(/^\w+$/)) {
        locale = "en_US";
      }
      return callback(locale);
    });
  };

  // Parse the output of the `env` command into a JavaScript object.
  parseEnv = function(stdout) {
    var env, i, len, line, match, matches, name, ref, value;
    env = {};
    ref = stdout.split("\n");
    for (i = 0, len = ref.length; i < len; i++) {
      line = ref[i];
      if (matches = line.match(/([^=]+)=(.+)/)) {
        [match, name, value] = matches;
        env[name] = value;
      }
    }
    return env;
  };

}).call(this);
