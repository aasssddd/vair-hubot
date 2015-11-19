# ThaiAppTask.coffee
# Description:
#   Send Passengers Manifest to SITA FTP Server
# Commands:
#	hubot resend sita batch - manual trigger send action, if something get wrong
# Notes:
#   web service to call avantik web service

###
	scheduled send passengers information to SITA
###
config = require 'app-config'
tosource = require 'tosource'
soap = require 'soap'
Cookie = require 'soap-cookie'
fs = require 'fs'
string = require 'string'
schedule = require 'node-schedule'
dateFormat = require 'dateformat'
{parseString} = require 'xml2js'
moment = require 'moment'
async = require 'async'
{AvantikInitBean, PassengerManifestReq} = require './lib/avantik-bean'
{serviceInitialize} = require './avantik-service-init'
{getPassengerManifest} = require './avantik-customer-info'
{SitaAirCarrierCSV, SitaAirCarrierRecord} = require './lib/sita-csv-generator'
{getFlightSchedule} = require './lib/avantik-flight-schedule'
{S3FileAccessHelper} = require './lib/upload-to-s3'

module.exports = (robot) ->

	###
		daily job:
			retrive flight schedule and create scheduled job
	###
	robot.on 'retriveSchedule', () ->
		time_zone_offset = config.avantik.GMT_HOUR
		qry_date = moment().format("YYYYMMDD")
		args = 
			fdate: qry_date

		getFlightSchedule args, (err, res) ->
			#run job 3 hours earlier before departure
			job_trigger_offset_hour = -3
			if err != ""
				robot.logger.error "Err #{err}"
				robot.send "Err #{err}"
			else
				# set schedule task 
				for j in res
					flightDetail = j.Flights.Details[0]
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
					robot.logger.debug "JOB is scheduled at #{schedule_date.toDate()}"
					schedule.scheduleJob schedule_date.toDate(), (data) ->
						robot.emit 'sendPassengerInfo', data

	robot.respond /resend sita on flight\s*(.*)? at *\s*(.*)?/i, (res) ->
		time_offset = parseInt config.avantik.GMT_HOUR
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
				for j in sch_res
					flightDetail = j.Flights.Details[0]
					data = 
						flight_no: flightDetail.flight_number[0]
						dep_date: flightDetail.departure_date[0].split(" ")[0]
						dep_time: string(flightDetail.planned_departure_time[0]).padLeft(4, "0").toString()
						arr_date: flightDetail.arrival_date[0].split(" ")[0]
						arr_time: string(flightDetail.planned_arrival_time[0]).padLeft(4, "0").toString()
					robot.logger.info "query passenger information with parameters: \n #{tosource data}"
					robot.emit 'sendPassengerInfo', data

	###
		data:
			flight_no: flight number
			dep_date: YYYYMMDD
			dep_time: HHMM
			arr_date: YYYYMMDD
			arr_time: HHMM
	###
	robot.on 'sendPassengerInfo', (data) ->
		# init avantik service
		initBean = new AvantikInitBean
		avantik_dateformat_string = "YYYYMMDD"
		avantik_date_req_string = "YYYY/MM/DD"
		wait_file_save_exec = 2000
		errMsg = ""

		soap.createClient initBean.url, (err, client) ->
			if err? 
				errMsg = err
			else
				processed = false
				serviceInitialize client, initBean, (err, initResult) ->
					if err?
						errMsg += "#{err}"
					else if "000" not in initResult.error.code
						errMsg += "#{initResult.error.code} #{initResult.error.message}"
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

						getPassengerManifest args, client, (passErr, passResult) ->
							if passErr?
								errMsg += "err! #{JSON.stringify passErr}"
							else
								robot.logger.debug "request header: \n#{JSON.stringify client.lastRequestHeaders}"
								robot.logger.debug "request: \n#{client.lastRequest}"
								robot.logger.debug "response: \n#{client.lastResponse}"

							# convert into SITA file format
							flightInfo = passResult.root.Flight[0]
							
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
								file_name = "#{flight_num}#{dateFormat depDateOri, partial_file_name_format}.csv"

								# save csv file
								robot.logger.info "starting generate target files"
								csvGenerator.commit_2 file_name, () ->
									setTimeout ()->
										# upload to S3	
										robot.logger.info "starting upload file to s3"
										filePath = config.avantik.SITA_CSV_FILE_PATH
										S3FileAccessHelper.UploadFile filePath + file_name, (err, data) ->
											if err?
												robot.reply "Err: #{err}"
											else
												robot.logger.info "file #{file_name} uploaded"
												robot.reply "S3_upload Ok!"

												# TODO: send to SITA

												# TODO: remove local file

												# send success / fail message to chat room
												if errMsg != ""
													robot.reply "Oops! transfer passenger information to SITA error: #{errMsg}"
												else
													robot.reply "Data has sent for you"
									, wait_file_save_exec