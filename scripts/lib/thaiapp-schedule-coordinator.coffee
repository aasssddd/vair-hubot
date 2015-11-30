# thaiapp-schedule-coordinator.coffee

###
use for manage schedule job
###

{log} = require "./vair-logger"
schedule = require "node-schedule"
config = require 'app-config'
tosource = require 'tosource'


class thaiAppScheduleCoordinator
	###
		avantik api call frequency
	###
	
	@passengerQueryJobs = []

	@sitaScheduleJobs = []

	###
		add schedule method
	###
	@addPassengerQueryJob: (flight_no, queryMethod) ->
		passengerQueryFreq = config.avantik.PASSENGER_MANIFEST_QUERY_FREQUENCY
		log.info "add passenger query job of flight #{flight_no}"
		job = schedule.scheduleJob passengerQueryFreq, queryMethod
		@passengerQueryJobs.push {"#{flight_no}": job}


	###
		add send to sita schedule
	###
	@addSitaScheduleJob: (flight_no, scheduleDate, jobMethod) ->
		log.info "add sita schedule job of flight #{flight_no} at #{scheduleDate}"
		job = schedule.scheduleJob scheduleDate, jobMethod
		@sitaScheduleJobs.push {"#{flight_no}": job}

	###
		return true /false
	###
	@cancelSitaScheduleJob: (flight_no) ->
		log.warning "canceling sita schedule job of flight #{flight_no}"
		job = @sitaScheduleJobs.filter (item) ->
			item[flight_no]
		if job? && job[0]?
			result = schedule.cancelJob job[0][flight_no]

			if result
				index = @sitaScheduleJobs.indexOf job[0]
				@sitaScheduleJobs.splice index, 1
			else
				log.error "fail canceling sita schedule job of flight #{flight_no}"
			return result

	###
		return true / false
	###
	@cancelPassengerQueryJob: (flight_no) ->
		log.warning "canceling passenger query job of flight #{flight_no}"
		job = @passengerQueryJobs.filter (item) ->
			item[flight_no]

		if job? && job[0]?
			result = schedule.cancelJob job[0][flight_no]
			if result
				index = @passengerQueryJobs.indexOf job[0]
				@passengerQueryJobs.splice index, 1
			else 
				log.error "fail canceling passenger query job of flight #{flight_no}"
			return result

	@cancelAllSitaJobs: () ->
		for key, value of @sitaScheduleJobs
			for k, v of value
				@cancelSitaScheduleJob k

		# reset collections
		@sitaScheduleJobs = []

	@cancelAllPassengerQueryJobs: () ->
		for key, value of @passengerQueryJobs
			for k, v of value
				@cancelPassengerQueryJob k

		# reset collections
		@passengerQueryJobs = []

	@cancelAllJobs: () ->
		@cancelAllSitaJobs()
		@cancelAllPassengerQueryJobs()

	###
		return list of passenger manifest query jobs
	###
	@listCurrentPassengerQueryJobs: () ->
		return @passengerQueryJobs

	###
		return list of sita schedule jobs
	###
	@listCurrentSitaScheduleJobs: () ->
		return @sitaScheduleJobs

module.exports.thaiAppScheduleCoordinator = thaiAppScheduleCoordinator