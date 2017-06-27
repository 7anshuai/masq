dgram = require "dgram"
fs = require "fs"
path = require "path"
{testCase} = require "nodeunit"
{Configuration, Daemon} = require ".."

module.exports = testCase
    setUp: (proceed) ->
        proceed()

    "start and stop": (test) ->
        test.expect 2

        configuration = new Configuration MASQ_DNS_PORT: 0
        daemon = new Daemon configuration

        daemon.start()
        daemon.on "start", ->
            test.ok daemon.started
            daemon.stop()
            daemon.on "stop", ->
                test.ok !daemon.started
                test.done()

    "start rolls back when it can't boot a server": (test) ->
        test.expect 2

        server = dgram.createSocket('udp4')
        server.bind 0, ->
            port = server.address().port
            configuration = new Configuration MASQ_DNS_PORT: port
            daemon = new Daemon configuration

            daemon.start()
            daemon.on "error", (err) ->
                test.ok err
                test.ok !daemon.started
                server.close()
                test.done()
