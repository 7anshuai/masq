# The `Configuration` class encapsulates various options for a Masq
# daemon (port numbers, directories, etc.). It's also responsible for
# creating `Logger` instances and mapping hostnames to application
# root paths.

fs                = require "fs"
path              = require "path"
async             = require "async"
Logger            = require "./logger"
{sourceScriptEnv} = require "./utils"
{getUserEnv}      = require "./utils"

module.exports = class Configuration
    # The user configuration file, `~/.masqconfig`, is evaluated on
    # boot.  You can configure options such as the top-level domain,
    # number of workers, the worker idle timeout, and listening ports.
    #
    #           export MASQ_DOMAINS=dev,test
    #           export MASQ_DNS_PORT=20561
    #
    # See the `Configuration` constructor for a complete list of
    # environment options.
    @userConfigurationPath: path.join process.env.HOME, ".masqconfig"

    # Evaluates the user configuration script and calls the `callback`
    # with the environment variables if the config file exists. Any
    # script errors are passed along in the first argument. (No error
    # occurs if the file does not exist.)
    @loadUserConfigurationEnvironment: (callback) ->
        getUserEnv (err, env) =>
            if err
                callback err
            else
                fs.exists p = @userConfigurationPath, (exists) ->
                    if exists
                        sourceScriptEnv p, env, callback
                    else
                        callback null, env

    # Creates a Configuration object after evaluating the user
    # configuration file. Any environment variables in `~/.masqconfig`
    # affect the process environment and will be copied to spawned
    # subprocesses.
    @getUserConfiguration: (callback) ->
        @loadUserConfigurationEnvironment (err, env) ->
            if err
                callback err
            else
                callback null, new Configuration env

    # A list of option names accessible on `Configuration` instances.
    @optionNames: [
        "bin", "dnsPort", "domains", "extDomains", "logRoot"
    ]

    # Pass in any environment variables you'd like to override when
    # creating a `Configuration` instance.
    constructor: (env = process.env) ->
        @logger = {}
        @initialize env

    # Valid environment variables and their defaults:
    initialize: (env) ->
        # `MASQ_BIN`: the path to the `masq` binary. (This should be
        # correctly configured for you.)
        @bin        = env.MASQ_BIN         ? path.join __dirname, "../bin/masq"

        # `MASQ_DNS_PORT`: the UDP port Masq listens on for incoming DNS
        # queries. Defaults to `20560`.
        @dnsPort    = env.MASQ_DNS_PORT    ? 20560

        # `MASQ_DOMAINS`: the top-level domains for which Masq will respond
        # to DNS `A` queries with `127.0.0.1`. Defaults to `dev`. If you
        # configure this in your `~/.masqconfig` you will need to re-run
        # `sudo masq --install-system` to make `/etc/resolver` aware of
        # the new TLDs.
        @domains    = env.MASQ_DOMAINS     ? env.MASQ_DOMAINS ? "dev"

        # `MASQ_EXT_DOMAINS`: additional top-level domains for which Masq
        # will serve HTTP requests (but not DNS requests -- hence the
        # "ext").
        @extDomains = env.MASQ_EXT_DOMAINS ? []

        # Allow for comma-separated domain lists, e.g. `MASQ_DOMAINS=dev,test`
        @domains    = @domains.split?(",")    ? @domains
        @extDomains = @extDomains.split?(",") ? @extDomains
        @allDomains = @domains.concat @extDomains

        # Support *.xip.io top-level domains.
        @allDomains.push /\d+\.\d+\.\d+\.\d+\.xip\.io$/, /[0-9a-z]{1,7}\.xip\.io$/

        # Runtime support files live in `~/Library/Application Support/Masq`.
        @supportRoot = libraryPath "Application Support", "Masq"

        # `MASQ_LOG_ROOT`: path to the directory that Masq will use to store
        # its log files. Defaults to `~/Library/Logs/Masq`.
        @logRoot    = env.MASQ_LOG_ROOT    ? libraryPath "Logs", "Masq"

        # Precompile regular expressions for matching domain names to be
        # served by the DNS server.
        @dnsDomainPattern  = compilePattern @domains

    # Gets an object of the `Configuration` instance's options that can
    # be passed to `JSON.stringify`.
    toJSON: ->
      result = {}
      result[key] = @[key] for key in @constructor.optionNames
      result

    # Retrieve a `Logger` instance with the given `name`.
    getLogger: (name) ->
      @loggers[name] ||= new Logger path.join @logRoot, name + ".log"

# Convenience wrapper for constructing paths to subdirectories of
# `~/Library`.
libraryPath = (args...) ->
  path.join process.env.HOME, "Library", args...

# Helper function for compiling a list of top-level domains into a
# regular expression for matching purposes.
compilePattern = (domains) ->
  /// ( (^|\.) (#{domains.join("|")}) ) \.? $ ///i
