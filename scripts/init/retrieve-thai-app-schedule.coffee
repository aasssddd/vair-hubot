# retrieve-thai-app-schedule.coffee

module.exports = (robot) ->
	robot.logger.info "retrieve thai app schedule"
	robot.emit 'retriveSchedule'