# ThaiAppTask.coffee

###
scheduled send passengers information to SITA
###
config = require 'app-config'
tosource = require 'tosource'
soap = require 'soap'
Cookie = require 'soap-cookie'
fs = require 'fs'
string = require 'string'
dateFormat = require 'dateformat'
{parseString} = require 'xml2js'
moment = require 'moment'
async = require 'async'
{SendToSita} = require './lib/sita-sender'
{thaiAppScheduleCoordinator} = require './lib/thaiapp-schedule-coordinator'
{AvantikInitBean, PassengerManifestReq} = require './lib/avantik-bean'
{serviceInitialize} = require './avantik-service-init'
{getPassengerManifest} = require './avantik-customer-info'
{SitaAirCarrierCSV, SitaAirCarrierRecord} = require './lib/sita-csv-generator'
{getFlightSchedule} = require './lib/avantik-flight-schedule'
{postFileToSlack} = require './lib/slack-file-poster'
{wrapErrorMessage, getSitaFileName, sitaScheduleHouseKeeping, checkAndWaitFileGenerate} = require './thai-app-utils'
{S3FileAccessHelper} = require './lib/upload-to-s3'

module.exports = (robot) ->

	robot.on 'listAllSchedule', ()->
		room = config.avantik.AVANTIK_MESSAGE_ROOM
		robot.messageRoom room, "passenger schedule: #{JSON.stringify thaiAppScheduleCoordinator.listCurrentPassengerQueryJobs()}"
		robot.messageRoom room, "sita schedule: #{JSON.stringify thaiAppScheduleCoordinator.listCurrentSitaScheduleJobs()}"

	###
		daily job:
			retrive flight schedule and create scheduled job
	###
	robot.on 'retriveSchedule', () ->

		room = config.avantik.AVANTIK_MESSAGE_ROOM

		# house keeping
		sitaScheduleHouseKeeping()

		passenger_query_frequency = config.avantik.PASSENGER_MANIFEST_QUERY_FREQUENCY

		qry_date = moment().format("YYYYMMDD")
		args = 
			fdate: qry_date

		robot.logger.info "retriveSchedule with params #{qry_date}"

		getFlightSchedule args, (err, res) ->
			#run job 3 hours earlier before departure
			job_trigger_offset_hour = config.avantik.SITA_SEND_TIME_SHIFT
			if err != ""
				robot.logger.error "Err #{err}"
				robot.messageRoom room, wrapErrorMessage "#{err}"
			else
				# set schedule task 
				res.forEach (item) ->
					flightDetail = item.Flights.Details[0]
					data = 
						flight_no: flightDetail.flight_number[0]
						dep_date: flightDetail.departure_date[0].split(" ")[0]
						dep_time: string(flightDetail.planned_departure_time[0]).padLeft(4, "0").toString()
						arr_date: flightDetail.arrival_date[0].split(" ")[0]
						arr_time: string(flightDetail.planned_arrival_time[0]).padLeft(4, "0").toString()

					robot.logger.debug "JOB Request data is: #{tosource data}"

					# set sechedule
					schedule_date = moment data.dep_date.split(" ")[0], "YYYYMMDD"
					schedule_time = data.dep_time.toString().match /.{1,2}/g
					schedule_date.hour schedule_time[0]
					schedule_date.minute schedule_time[1]
					schedule_date.add job_trigger_offset_hour, 'hour'				

					# set passenger query jobs
					thaiAppScheduleCoordinator.addPassengerQueryJob data.flight_no, ((obj) ->
						robot.emit 'sendPassengerInfo', obj
						).bind null, data

					#define file name
					file_name = getSitaFileName data.flight_no, data.dep_date

					# set sita schedule jobs
					thaiAppScheduleCoordinator.addSitaScheduleJob data.flight_no, schedule_date.toDate(), ((obj) ->
						retry_file_test = config.avantik.SITA_FILE_CHECK_TIMEOUT_SECOND
						fileExist = checkAndWaitFileGenerate file_name, retry_file_test, (err) ->
							if err?
								robot.logger.warning "file #{file_name} not found for #{retry_file_test} seconds, maybe there is no data found for #{data.flight_no}"
								robot.messageRoom room, "Attention! Flight number: #{data.flight_no} does not contains any passenger data"
							else
								SendToSita file_name, (err) ->
									if err?
										robot.logger.error "fail sending file to sita"
										robot.messageRoom room, wrapErrorMessage "fail sending file to sita"
									else
										robot.messageRoom room, "file #{file_name} has sent to SITA"

								# upload to S3	
								robot.logger.info "starting upload file #{file_name} to s3"
								
								S3FileAccessHelper.UploadFile file_name, (s3Err, data) ->
									if err?
										robot.logger.error "file #{file_name} upload to S3 fail"
										robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, wrapErrorMessage "file upload to s3 error: #{s3Err}"
									else
										robot.logger.info "file #{file_name} uploaded to S3"

								# POST file to Slack Channel
								postFileToSlack file_name, config.avantik.AVANTIK_MESSAGE_ROOM, (err, resp) ->
									if err?
										robot.logger.error "send file to message channel fail: #{err}"
									else
										robot.logger.debug "send file result #{tosource resp}"
										robot.logger.info "send file #{file_name} to slack successful"

								

							# un-register SITA job 
							thaiAppScheduleCoordinator.cancelSitaScheduleJob data.flight_no

							#un-register avantik job
							thaiAppScheduleCoordinator.cancelPassengerQueryJob data.flight_no
							robot.logger.info "unbind task of #{data.flight_no}"

						).bind null, file_name

	robot.on 'sendFileToSitaNow', (flight_no) ->
		path = config.avantik.SITA_CSV_FILE_PATH
		room = config.avantik.AVANTIK_MESSAGE_ROOM
		files = fs.readdirSync path

		if files?
			fileSearchPattern = "ZV#{flight_no}"
			search_result = files.filter (file_name) ->
				match = file_name.indexOf fileSearchPattern
				robot.logger.info "file #{file_name} matches #{fileSearchPattern}? #{match}"
				return match > -1
			if search_result.length >= 1
				return SendToSita search_result[0], (err) ->
					if err?
						robot.logger.error wrapErrorMessage "#{err}"
					else
						robot.messageRoom  room, "file #{search_result} is sent for you"

		robot.messageRoom room, "CSV Files not found, please make sure flight number is exist, or try regenerate file you need"