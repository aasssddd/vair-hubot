# init.coffee
path = require 'path'
fs = require 'fs'
Logger = require('vair_log').Logger
module.exports = (robot) ->
	log = Logger.getLogger()
	initscript = path.resolve __dirname, 'init'
	fs.exists initscript, (exists) ->
    if exists
    	log.info "found init scripts"
    	robot.loadFile initscript, file for file in fs.readdirSync(initscript)