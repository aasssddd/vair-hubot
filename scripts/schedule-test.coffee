# schedule-test.coffee
schedule = require 'node-schedule'

module.exports = (robot) ->
	robot.respond /add task\s*(.*)? at\s*(.*)$/i, (res) ->
		task = res.match[1]
		date = new Date res.match[2]
		console.log "trigger #{task} at #{date}"
		robot.emit task, {"date": date}

	###
		do some job
	###
	robot.on 'demo', (data) ->
		console.log "demo job is trigger with data: #{JSON.stringify data}"
		schedule.scheduleJob data.date, () ->
			console.log "event triggered! #{new Date}"
			robot.send "event triggered!"