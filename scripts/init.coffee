# init.coffee
path = require 'path'
fs = require 'fs'
module.exports = (robot) ->
	initscript = path.resolve __dirname, 'init'
	fs.exists initscript, (exists) ->
    if exists
    	robot.logger.info "found init scripts"
    	robot.loadFile initscript, file for file in fs.readdirSync(initscript)