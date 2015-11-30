# vair-logger.coffee

Log = require 'log'

level = process.env.HUBOT_LOG_LEVEL
if not level?
	level = "info"

log = new Log(level)

module.exports.log = log