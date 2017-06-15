# A `Daemon` is the root object in a Masq process. It's responsible for
# starting and stopping a `DnsServer` in tandem.

{EventEmitter} = require "events"
DnsServer      = require "./dns_server"
fs             = require "fs"
path           = require "path"

module.exports = class Daemon extends EventEmitter
    # Create a new `Daemon` with the given `Configuration` instance.
    constructor: (@configuration) ->
        super()
        @dnsServer = new DnsServer @configuration
        # The daemon stops in response to `SIGINT`, `SIGTERM` and
        # `SIGQUIT` signals.
        process.on "SIGINT",  @stop
        process.on "SIGTERM", @stop
        process.on "SIGQUIT", @stop

    start: ->
        return if @starting or @started
        @starting = true

        startServer = (server, port, callback) -> process.nextTick ->
            try
                server.on 'error', callback

                server.once 'listening', ->
                    server.removeListener 'error', callback
                    callback()

                server.listen port

            catch err
                callback err

        pass = =>
            @starting = false
            @started = true
            @emit "start"

        flunk = (err) =>
            @starting = false
            try @dnsServer.close()
            @emit "error", err

        startServer @dnsServer, @configuration.dnsPort, (err) ->
            if err then flunk err
            else pass()

    # Stop the daemon if it's started. This means calling `close` on
    # both servers in succession, beginning with the HTTP server, and
    # waiting for the servers to notify us that they're done. The daemon
    # emits a `stop` event when this process is complete.
    stop: ->
        return if @stopping or !@started
        @stopping = true

        stopServer = (server, callback) -> process.nextTick ->
            try
                close = ->
                    server.removeListener "close", close
                    callback null
                server.on "close", close
                server.close()
            catch err
                callback err

        stopServer @dnsServer, =>
            @stopping = false
            @started  = false
            @emit "stop"

