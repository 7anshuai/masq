fs            = require 'fs'
{spawn, exec} = require 'child_process'
async = require('async')

build = (watch, callback) ->
    if typeof watch is 'function'
        callback = watch
        watch = false
    options = ['-c', '-o', 'lib', 'src']
    options.unshift '-w' if watch

    coffee = spawn 'node_modules/.bin/coffee', options
    coffee.stdout.on 'data', (data) -> console.log data.toString()
    coffee.stderr.on 'data', (data) -> console.log data.toString()
    coffee.on 'exit', (status) -> callback?() if status is 0

buildTemplates = (callback) ->
    eco = require 'eco'
    compile = (name) ->
        (callback) ->
            fs.readFile "src/templates/#{name}.eco", "utf8", (err, data) ->
                if err then callback err
                else fs.writeFile "lib/templates/#{name}.js", "module.exports = #{eco.precompile(data)}", callback

    async.parallel [
        compile('resolver')
        compile('cx.masq.masqd.plist')
        compile('cx.masq.firewall.plist')
    ], callback

task 'docs', 'Generate annotated source code with Docco', ->
    fs.readdir 'src', (err, contents) ->
        files = ("src/#{file}" for file in contents when /\.coffee$/.test file)
        docco = spawn 'node_modules/.bin/docco', files
        docco.stdout.on 'data', (data) -> console.log data.toString()
        docco.stderr.on 'data', (data) -> console.log data.toString()
        docco.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile CoffeeScript source files', ->
    build()
    buildTemplates()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
    build true

task 'test', 'Run the Masq test suite', ->
    build ->
        process.env["NODE_ENV"] = "test"

        {reporters} = require 'nodeunit'
        process.chdir __dirname
        reporters.default.run ['test']
