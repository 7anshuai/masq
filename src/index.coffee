# This is the annotated source code for [Pow](http://pow.cx/), a
# zero-configuration Rack server for Mac OS X. See the [user's
# manual](http://pow.cx/manual.html) for information on installation
# and usage.
#
# The annotated source HTML is generated by
# [Docco](http://jashkenas.github.com/docco/).

# ## Table of contents
module.exports =

    # The [Configuration](configuration.html) class stores settings for
    # a Pow daemon and is responsible for mapping hostnames to Rack
    # applications.
    Configuration: require "./configuration"

    # The [Daemon](daemon.html) class represents a running Pow daemon.
    Daemon:        require "./daemon"

    # [DnsServer](dns_server.html) handles incoming DNS queries.
    DnsServer:     require "./dns_server"

    # [Installer](installer.html) compiles and installs local and system
    # configuration files.
    Installer:       require "./installer"

    # [Logger](logger.html) instances keep track of everything that
    # happens during a Pow daemon's lifecycle.
    Logger:          require "./logger"

    # The [utils](utils.html) module contains various helper functions.
    utils:            require "./utils"