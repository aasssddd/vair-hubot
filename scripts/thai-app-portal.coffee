# thai-app-portal.coffee
# Description:
#   Send Passengers Manifest to SITA FTP Server
# Commands:
#	hubot list all sita schedule - [Developer command] See scheduled tasks
#	hubot clean everything about sita - hope you will never use this command
# 	hubot send sita passenger data of flight <flight number> now
#	hubot restart sita schedule - manual trigger send action, if something goes wrong
#	hubot generate sita data on flight <flight number> at <when> - flight number: node need ZV, when: yyyy/mm/dd
#
# Notes:
#   portal for manipulate thai-app
#

moment = require 'moment'
string = require 'string'
tosource = require 'tosource'
config = require 'app-config'
fs = require 'fs'
async = require 'async'
{postFileToSlack} = require './lib/slack-file-poster'
{SendToSita} = require './lib/sita-sender'
{getFlightSchedule} = require './lib/avantik-flight-schedule'
{wrapErrorMessage, getSitaFileName, sitaScheduleHouseKeeping, checkAndWaitFileGenerate} = require './thai-app-utils'
Logger = require('vair_log').Logger

module.exports = (robot) ->
	log = Logger.getLogger()
	###
		list all schedule
	###
	robot.respond /list all sita schedule/i, (res) ->
		robot.emit 'listAllSchedule'

	###
		reset all schedule
	###
	robot.respond /restart sita schedule/i, (res) ->
		robot.emit 'retriveSchedule'
		res.reply "Aye Sir, you can check sita schedule next invocation time now"

	robot.respond /clean everything about SITA/i, (res)->
		sitaScheduleHouseKeeping()
		res.reply "data has been clean for you"

	###
		send to sita immediately
	###
	robot.respond /send sita passenger data of flight\s*(.*)? now/i, (res) ->
		flight_no = res.match[1]
		robot.emit 'sendFileToSitaNow', flight_no

	###
		resend file to sita
	###
	robot.respond /generate sita data on flight\s*(.*)? at *\s*(.*)?/i, (res) ->
		res.reply "Aye Sir! Please wait one minute"
		args = 
			flight: res.match[1]
			fdate: moment(res.match[2], "YYYY/MM/DD").format("YYYYMMDD")
		log.info "starting to resend data of #{JSON.stringify args}"

		getFlightSchedule args, (err, sch_res) ->
			if err != ""
				log.error "Err #{err}"
				robot.send "Err #{err}"
			else
				# set schedule task 
				log.info "found schedule data: #{JSON.stringify sch_res}"
				sch_res.forEach (item) ->

					flightDetail = item.Flights.Details[0]
					data = 
						flight_no: flightDetail.flight_number[0]
						dep_date: flightDetail.departure_date[0].split(" ")[0]
						dep_time: string(flightDetail.planned_departure_time[0]).padLeft(4, "0").toString()
						arr_date: flightDetail.arrival_date[0].split(" ")[0]
						arr_time: string(flightDetail.planned_arrival_time[0]).padLeft(4, "0").toString()
					log.info "query passenger information with parameters: #{tosource data}"
					
					robot.emit 'sendPassengerInfo', data, (err) ->
						if err?
							res.reply "create sita file error: #{err}"
						else
							pattern = "ZV#{args.flight}#{args.fdate}"

							files = fs.readdirSync config.avantik.SITA_CSV_FILE_PATH

							if files?
								search_result = files.filter (file_name) ->
									match = file_name.indexOf pattern
									if match > -1
										log.info "file #{file_name} matches #{pattern}"
									return match > -1
								if search_result.length >= 1
									search_result.forEach (fileObj) ->
										log.info "starting send ftp file"
										SendToSita fileObj, (err) ->
											if err?
												log.error wrapErrorMessage "#{err}"
												res.reply "send file to SITA error, maybe something broken, pls try later or send manually"
											else
												res.reply "file #{fileObj} has sent to sita"
												postFileToSlack fileObj, config.avantik.AVANTIK_MESSAGE_ROOM, (err, body) ->
													if err?
														log.error "post file to slack fail: #{err}"
														res.reply "post file to slack fail #{err}"
													else
														log.info "file posted to slack"
														log.info "slack post result: #{body}"
