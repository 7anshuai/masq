{DnsServer} = require ".."
async       = require "async"
{exec}      = require "child_process"
{testCase}  = require "nodeunit"

{createConfiguration} = require "./lib/test_helper"

module.exports = testCase
    setUp: (proceed) ->
        proceed()

    "responds to all A queries for the configured domain": (test) ->
        test.expect 12

        exec "which dig", (err) ->
            if err
                console.warn "Skipping test, system is missing `dig`"
                test.expect 0
                test.done()
            else
                configuration = createConfiguration MASQ_DOMAINS: "masqtest,masqdev"
                dnsServer = new DnsServer configuration
                address = "0.0.0.0"
                port = 20561

                dnsServer.listen port, ->
                    resolve = (domain, callback) ->
                        cmd = "dig -p #{port} @#{address} #{domain} +noall +answer +comments"
                        exec cmd, (err, stdout, stderr) ->
                            status = stdout.match(/status: (.*?),/)?[1]
                            answer = stdout.match(/IN\tA\t([\d.]+)/)?[1]
                            callback err, status, answer

                    testResolves = (host, expectedStatus, expectedAnswer) ->
                        (callback) -> resolve host, (err, status, answer) ->
                            test.ifError err
                            test.same [expectedStatus, expectedAnswer], [status, answer]
                            callback()

                    async.parallel [
                        testResolves "hello.masqtest", "NOERROR", "127.0.0.1"
                        testResolves "hello.masqdev",  "NOERROR", "127.0.0.1"
                        testResolves "a.b.c.masqtest", "NOERROR", "127.0.0.1"
                        testResolves "masqtest.",      "NOERROR", "127.0.0.1"
                        testResolves "masqdev.",       "NOERROR", "127.0.0.1"
                        testResolves "foo.",           "NXDOMAIN"
                    ], ->
                        dnsServer.close()
                        test.done()
