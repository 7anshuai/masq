# The `command` module is loaded when the `masq` binary runs. It parses
# any command-line arguments and determines whether to install Pow's
# configuration files or start the daemon itself.

{Daemon, Configuration, Installer} = require ".."

# Set the process's title to `masq` so it's easier to find in `ps`,
# `top`, Activity Monitor, and so on.
process.title = "masq"

# Print valid command-line arguments and exit with a non-zero exit
# code if invalid arguments are passed to the `masq` binary.
usage = ->
    console.error "usage: masq [--print-config | --install-local | --install-system [--dry-run]]"
    process.exit -1

# Start by loading the user configuration from `~/.masqconfig`, if it
# exists. The user configuration affects both the installer and the
# daemon.
Configuration.getUserConfiguration (err, configuration) ->
    throw err if err

    printConfig = false
    dryRun = false
    createInstaller = null

    for arg in process.argv.slice(2)
        # Set a flag if `--print-config` is requested.
        if arg is "--print-config"
            printConfig = true
        # Cache the factory method for creating a local or system
        # installer if necessary.
        else if arg is "--install-local"
            createInstaller = Installer.getLocalInstaller
        else if arg is "--install-system"
            createInstaller = Installer.getSystemInstaller
        # Set a flag if a dry run is requested.
        else if arg is "--dry-run"
            dryRun = true
        else
            usage()

    # Abort if a dry run is requested without installing anything.
    if dryRun and not createInstaller
        usage()

    # Print out the current configuration in a format that can be
    # evaluated by a shell script (`eval $(pow --print-config)`).
    else if printConfig
        underscore = (string) ->
            string.replace /(.)([A-Z])/g, (match, left, right) ->
                left + "_" + right.toLowerCase()

        shellEscape = (string) ->
            "'" + string.toString().replace(/'/g, "'\\''") + "'"

        for key, value of configuration.toJSON()
            console.log "MASQ_" + underscore(key).toUpperCase() +
                "=" + shellEscape(value)

    # Create the installer, passing in our loaded configuration.
    else if createInstaller
        installer = createInstaller configuration
        # If a dry run was requested, check to see whether any files need
        # to be installed with root privileges. If yes, exit with a status
        # of 1. If no, exit with a status of 0.
        if dryRun
            installer.needsRootPrivileges (needsRoot) ->
                exitCode = if needsRoot then 1 else 0
                installer.getStaleFiles (files) ->
                    console.log file.path for file in files
                    process.exit exitCode
        # Otherwise, install all the requested files, printing the full
        # path of each installed file to stdout.
        else
            installer.install (err) ->
                throw err if err

    # Start up the Pow daemon if no arguments were passed. Terminate the
    # process if the daemon requests a restart.
    else
        daemon = new Daemon configuration
        daemon.on "restart", -> process.exit()
        daemon.start()
