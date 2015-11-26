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
SendToSita = require './lib/sita-sender'
ThaiAppScheduleCoordinator = require './lib/thaiapp-schedule-coordinator'
{AvantikInitBean, PassengerManifestReq} = require './lib/avantik-bean'
{serviceInitialize} = require './avantik-service-init'
{getPassengerManifest} = require './avantik-customer-info'
{SitaAirCarrierCSV, SitaAirCarrierRecord} = require './lib/sita-csv-generator'
{getFlightSchedule} = require './lib/avantik-flight-schedule'
{S3FileAccessHelper} = require './lib/upload-to-s3'
{postFileToSlack} = require './lib/slack-file-poster'
{WrapErrorMessage, getSitaFileName, sitaScheduleHouseKeeping} = require './thai-app-utils'


module.exports = (robot) ->

	###
		daily job:
			retrive flight schedule and create scheduled job
	###
	robot.on 'retriveSchedule', () ->
		
		# house keeping
		sitaScheduleHouseKeeping()

		qry_date = moment().format("YYYYMMDD")
		args = 
			fdate: qry_date

		robot.logger.info "retriveSchedule with params #{qry_date}"

		getFlightSchedule args, (err, res) ->
			#run job 3 hours earlier before departure
			job_trigger_offset_hour = config.avantik.SITA_SEND_TIME_SHIFT
			if err != ""
				robot.logger.error "Err #{err}"
				robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, WrapErrorMessage "#{err}"
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

					robot.logger.info "JOB Request data is: #{tosource data}"

					# set sechedule
					schedule_date = moment data.dep_date.split(" ")[0], "YYYYMMDD"
					schedule_time = data.dep_time.toString().match /.{1,2}/g
					schedule_date.hour schedule_time[0]
					schedule_date.minute schedule_time[1]
					schedule_date.add job_trigger_offset_hour, 'hour'				

					# set passenger query jobs
					ThaiAppScheduleCoordinator.addPassengerQueryJob data.flight_no, ((obj) ->
						robot.emit 'sendPassengerInfo', obj
						).bind null, data

					# set sita schedule jobs
					ThaiAppScheduleCoordinator.addSitaScheduleJob schedule_date.toDate(), ((obj) ->

						file_name = getSitaFileName data.dep_date
						SendToSita file_name

						# POST file to Slack Channel
						postFileToSlack file_name, config.avantik.AVANTIK_MESSAGE_ROOM, (err, resp) ->
							if err?
								robot.logger.error "send file to message channel fail: #{err}"
							else
								robot.logger.debug "send file result #{tosource resp}"

						# un-register job 
						ThaiAppScheduleCoordinator.cancelSitaScheduleJob data.flight_no

						).bind null, sita_file_name

	###
		data:
			flight_no: flight number
			dep_date: YYYYMMDD
			dep_time: HHMM
			arr_date: YYYYMMDD
			arr_time: HHMM
	###
	robot.on 'sendPassengerInfo', (data) ->

		robot.logger.info "query passenger info with parameters: #{tosource data}"
		# init avantik service
		initBean = new AvantikInitBean
		avantik_dateformat_string = "YYYYMMDD"
		avantik_date_req_string = "YYYY/MM/DD"
		wait_file_save_exec = 2000
		errMsg = ""

		soap.createClient initBean.url, (soapErr, client) ->
			if soapErr? 
				robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, WrapErrorMessage "#{soapErr}"
			else
				processed = false
				serviceInitialize client, initBean, (initErr, initResult) ->
					if err?
						robot.logger.error "Err: #{initErr}" 
						robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, WrapErrorMessage "#{initErr}"

					else if "000" not in initResult.error.code
						robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, WrapErrorMessage "#{initResult.error.code} #{initResult.error.message}"

					else
						robot.logger.debug "request: \n#{client.lastRequest}"
						robot.logger.debug "response: \n#{client.lastResponse}"
						robot.logger.debug "Init OK, #{initResult.error.code} #{initResult.error.message}"
						cookie = new Cookie(client.lastResponseHeaders)
						robot.logger.debug "Cookie: \n#{JSON.stringify cookie}"

						# set cookie
						client.setSecurity(cookie)

						# get passengers manifest
						args = new PassengerManifestReq()
						args.PassengersManifestRequest.airline_rcd = "ZV"
						args.PassengersManifestRequest.flight_number = data.flight_no
						args.PassengersManifestRequest.departure_date_from = moment(data.dep_date, avantik_dateformat_string).format avantik_date_req_string
						# args.PassengersManifestRequest.bCheckedIn = true

						getPassengerManifest args, client, (passErr, passResult) ->
							if passErr?
								robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, WrapErrorMessage "err! #{JSON.stringify passErr}"
							else
								robot.logger.debug "request header: \n#{JSON.stringify client.lastRequestHeaders}"
								robot.logger.debug "request: \n#{client.lastRequest}"
								robot.logger.debug "response: \n#{client.lastResponse}"

							# convert into SITA file format
							if !passResult.root?
								robot.logger.info "no data result message is: #{tosource passResult}"
								robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, "no passenger data found on flight #{data.flight_no} at #{data.dep_date}"
								return

							flightInfo = passResult.root.Flight[0]

							if !flightInfo
								robot.logger.info "no data result message is: #{tosource passResult}"
								robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, "no flight found"
								return
							
							sita_date_format_string = "dd-mmm-yyyy"
							partial_file_name_format = "yyyymmdd"

							# assume all passengers are Normal
							travel_type = "N"
							robot.logger.debug "flight info: #{tosource flightInfo}"
							depDateOri = moment(data.dep_date, avantik_dateformat_string).toDate()
							arrDateOri = moment(data.arr_date, avantik_dateformat_string).toDate()
							depDate = dateFormat depDateOri, sita_date_format_string
							depTime = data.dep_time
							arrDate = dateFormat arrDateOri, sita_date_format_string
							arrTime = data.arr_time
							flight_num = flightInfo.airline_rcd + flightInfo.flight_number
							csvGenerator = new SitaAirCarrierCSV flight_num, flightInfo.origin_rcd, depDate, depTime, flightInfo.destination_rcd, arrDate, arrTime

							# put passenger data
							passenger = flightInfo.Passenger
							
							async.forEachOf passenger, (item, key, cb) ->
								robot.logger.debug "passenger: #{JSON.stringify item}"
								passport_expiry_string = ""
								birthday_string = ""
								if item.passport_expiry_date?
									passport_expiry_string = dateFormat (new Date item.passport_expiry_date), sita_date_format_string
								if item.date_of_birth?
									birthday_string = dateFormat (new Date item.date_of_birth), sita_date_format_string								
								csvGenerator.add new SitaAirCarrierRecord "P", item.nationality_rcd, item.passport_number, passport_expiry_string, null, item.lastname, item.firstname,	birthday_string, item.gender_type_rcd, item.nationality_rcd, travel_type, null, null
								cb()
							, () ->
								#generate file name
								file_name = getSitaFileName data.dep_date

								# save csv file
								robot.logger.info "starting generate target files"
								filePath = config.avantik.SITA_CSV_FILE_PATH
								csvGenerator.commit_2 file_name, (writeErr) ->
									if writeErr?
										robot.logger.error "csv file write error: #{writeErr}"
										robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, "file #{file_name}"
									setTimeout ()->

										# upload to S3	
										robot.logger.info "starting upload file to s3"
										
										S3FileAccessHelper.UploadFile filePath + file_name, (s3Err, data) ->
											if err?
												robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, WrapErrorMessage "file upload to s3 error: #{s3Err}"
											else
												robot.logger.info "file #{file_name} uploaded"
												robot.reply "S3_upload Ok!"

									, wait_file_save_exec