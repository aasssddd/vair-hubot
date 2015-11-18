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
{AvantikInitBean, PassengerManifestReq} = require './lib/avantik-bean'
{serviceInitialize} = require './avantik-service-init'
{getPassengerManifest} = require './avantik-customer-info'
{SitaAirCarrierCSV, SitaAirCarrierRecord} = require './lib/sita-csv-generator'
{getFlightSchedule} = require './lib/avantik-flight-schedule'
{S3FileAccessHelper} = require './upload-to-s3'

module.exports = (robot) ->
	robot.on 'retriveSchedule', (date_input) ->
		qry_date = date_input? new Date()
		args = 
			fdate: qry_date

		getFlightSchedule args, (err, res) ->
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

	robot.respond /try schedule at\s*(.*)?/i, (res) ->
		robot.emit 'retriveSchedule', new Date(res.match[1])


	robot.respond /resend sita on flight\s*(.*)? at *\s*(.*)?/i, (res) ->
		args = 
			flight: res.match[1]
			fdate: new Date res.match[2]
			
		getFlightSchedule args, (err, res) ->
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
		errMsg = ""
		soap.createClient initBean.url, (err, client) ->
			if err? 
				errMsg = err
			else
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
							console.log "#{tosource flightInfo}"
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
							for d, i in passenger
								passport_expiry_string = ""
								birthday_string = ""
								if d.passport_expiry_date?
									passport_expiry_string = dateFormat (new Date d.passport_expiry_date), sita_date_format_string
								if d.date_of_birth?
									birthday_string = dateFormat (new Date d.date_of_birth), sita_date_format_string								
								csvGenerator.add new SitaAirCarrierRecord "P", d.nationality_rcd, d.passport_number, passport_expiry_string, null, d.lastname, d.firstname,	birthday_string, d.gender_type_rcd, d.nationality_rcd, travel_type, null, null
							
							#generate file name

							file_name = "#{flight_num}#{dateFormat depDateOri, partial_file_name_format}.csv"

							# save csv file
							csvGenerator.commit file_name
		
							# upload to S3
							S3FileAccessHelper.UploadFile file_name

							# TODO: send to SITA

							# TODO: remove local file

							# send success / fail message to chat room
							if errMsg != ""
								robot.messageRoom "Shell", "Oops! transfer passenger information to SITA error: #{errMsg}"
							else
								robot.messageRoom "Shell", "Passenger information  SITA"
