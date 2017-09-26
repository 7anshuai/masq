// Generated by CoffeeScript 2.0.0
(function() {
  var DnsServer, async, createConfiguration, exec, testCase;

  ({DnsServer} = require(".."));

  async = require("async");

  ({exec} = require("child_process"));

  ({testCase} = require("nodeunit"));

  ({createConfiguration} = require("./lib/test_helper"));

  module.exports = testCase({
    setUp: function(proceed) {
      return proceed();
    },
    "responds to all A queries for the configured domain": function(test) {
      test.expect(12);
      return exec("which dig", function(err) {
        var address, configuration, dnsServer, port;
        if (err) {
          console.warn("Skipping test, system is missing `dig`");
          test.expect(0);
          return test.done();
        } else {
          configuration = createConfiguration({
            MASQ_DOMAINS: "masqtest,masqdev"
          });
          dnsServer = new DnsServer(configuration);
          address = "0.0.0.0";
          port = 20561;
          return dnsServer.listen(port, function() {
            var resolve, testResolves;
            resolve = function(domain, callback) {
              var cmd;
              cmd = `dig -p ${port} @${address} ${domain} +noall +answer +comments`;
              return exec(cmd, function(err, stdout, stderr) {
                var answer, ref, ref1, status;
                status = (ref = stdout.match(/status: (.*?),/)) != null ? ref[1] : void 0;
                answer = (ref1 = stdout.match(/IN\tA\t([\d.]+)/)) != null ? ref1[1] : void 0;
                return callback(err, status, answer);
              });
            };
            testResolves = function(host, expectedStatus, expectedAnswer) {
              return function(callback) {
                return resolve(host, function(err, status, answer) {
                  test.ifError(err);
                  test.same([expectedStatus, expectedAnswer], [status, answer]);
                  return callback();
                });
              };
            };
            return async.parallel([testResolves("hello.masqtest", "NOERROR", "127.0.0.1"), testResolves("hello.masqdev", "NOERROR", "127.0.0.1"), testResolves("a.b.c.masqtest", "NOERROR", "127.0.0.1"), testResolves("masqtest.", "NOERROR", "127.0.0.1"), testResolves("masqdev.", "NOERROR", "127.0.0.1"), testResolves("foo.", "NXDOMAIN")], function() {
              dnsServer.close();
              return test.done();
            });
          });
        }
      });
    }
  });

}).call(this);
