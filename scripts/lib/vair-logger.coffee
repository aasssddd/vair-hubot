# vair-logger.coffee

Log = require 'log'
fs = require 'fs'

level = process.env.HUBOT_LOG_LEVEL
if not level?
	level = "info"

log = new Log(level, fs.createWriteStream "hubot.log")

module.exports.log = log