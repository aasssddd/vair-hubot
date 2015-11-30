# thai-app-portal.coffee

# Description:
#   Send Passengers Manifest to SITA FTP Server
# Commands:
#	hubot list all schedule - [Developer command] See scheduled tasks
#	hubot clean everything about SITA - hope you will never use this command
# 	hubot send sita passenger data of flight <flight number> now - no 
#	hubot restart sita schedule - manual trigger send action, if something goes wrong
#	hubot generate passenger data on flight <flight number> at <when> - flight number: node need ZV, when: yyyy/mm/dd
#
# Notes:
#   web service to call avantik web service


moment = require 'moment'
string = require 'string'
tosource = require 'tosource'
{SendToSita} = require './lib/sita-sender'
{getFlightSchedule} = require './lib/avantik-flight-schedule'
{WrapErrorMessage, getSitaFileName, sitaScheduleHouseKeeping} = require './thai-app-utils'

module.exports = (robot) ->

	###
		list all schedule
	###
	robot.respond /list all schedule/i, () ->
		robot.emit 'listAllSchedule'

	###
		reset all schedule
	###
	robot.respond /restart sita schedule/i, () ->
		robot.emit 'retriveSchedule'

	robot.respond /clean everything about SITA/i, ()->
		sitaScheduleHouseKeeping()

	###
		send to sita immediately
	###
	robot.respond /send sita passenger data of flight\s*(.*)? now/i, (res) ->
		flight_no = res.match[1]
		robot.emit 'sendFileToSitaNow', flight_no

	###
		resend file to sita
	###
	robot.respond /generate passenger data on flight\s*(.*)? at *\s*(.*)?/i, (res) ->
		args = 
		flight: res.match[1]
		fdate: moment(res.match[2], "YYYY/MM/DD").format("YYYYMMDD")
		robot.logger.info "starting to resend data of #{JSON.stringify args}"

		getFlightSchedule args, (err, sch_res) ->
			if err != ""
				robot.logger.error "Err #{err}"
				robot.send "Err #{err}"
			else
				# set schedule task 
				robot.logger.debug "found schedule data: #{JSON.stringify sch_res}"
				sch_res.forEach (item) ->
					flightDetail = item.Flights.Details[0]
					data = 
						flight_no: flightDetail.flight_number[0]
						dep_date: flightDetail.departure_date[0].split(" ")[0]
						dep_time: string(flightDetail.planned_departure_time[0]).padLeft(4, "0").toString()
						arr_date: flightDetail.arrival_date[0].split(" ")[0]
						arr_time: string(flightDetail.planned_arrival_time[0]).padLeft(4, "0").toString()
					robot.logger.info "query passenger information with parameters: #{tosource data}"
					robot.emit 'sendPassengerInfo', data

