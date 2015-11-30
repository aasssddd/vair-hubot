# passenger-query-schedule-setter.coffee

tosource = require 'tosource'
soap = require 'soap'
Cookie = require 'soap-cookie'
moment = require 'moment'
dateFormat = require 'dateformat'
async = require 'async'
config = require 'app-config'

{serviceInitialize} = require './avantik-service-init'
{getPassengerManifest} = require './avantik-customer-info'
{AvantikInitBean, PassengerManifestReq} = require './lib/avantik-bean'
{SitaAirCarrierCSV, SitaAirCarrierRecord} = require './lib/sita-csv-generator'
{postFileToSlack} = require './lib/slack-file-poster'
{wrapErrorMessage, getSitaFileName, sitaScheduleHouseKeeping} = require './thai-app-utils'

module.exports = (robot) ->
	###
		data:
			flight_no: flight number
			dep_date: YYYYMMDD
			dep_time: HHMM
			arr_date: YYYYMMDD
			arr_time: HHMM
	###
	robot.on 'sendPassengerInfo', (data) ->

		robot.logger.info "query passenger info of flight #{data.flight_no}"
		robot.logger.debug "query passenger info with parameters: #{tosource data}"
		# init avantik service
		initBean = new AvantikInitBean
		avantik_dateformat_string = "YYYYMMDD"
		avantik_date_req_string = "YYYY-MM-DD"
		wait_file_save_exec = 2000
		errMsg = ""

		soap.createClient initBean.url, (soapErr, client) ->
			if soapErr? 
				robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, wrapErrorMessage "#{soapErr}"
			else
				processed = false
				serviceInitialize client, initBean, (initErr, initResult) ->
					if err?
						robot.logger.error "Err: #{initErr}" 
						robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, wrapErrorMessage "#{initErr}"

					else if "000" not in initResult.error.code
						robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, wrapErrorMessage "#{initResult.error.code} #{initResult.error.message}"

					else
						robot.logger.debug "request: #{client.lastRequest}"
						robot.logger.debug "response: #{client.lastResponse}"
						robot.logger.debug "Init OK, #{initResult.error.code} #{initResult.error.message}"
						cookie = new Cookie(client.lastResponseHeaders)
						robot.logger.debug "Cookie: #{JSON.stringify cookie}"

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
								robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, wrapErrorMessage "err! #{JSON.stringify passErr}"
							else
								robot.logger.debug "request header: #{JSON.stringify client.lastRequestHeaders}"
								robot.logger.debug "request: #{client.lastRequest}"
								robot.logger.debug "response: #{client.lastResponse}"

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
								passport_expiry_string = null
								birthday_string = ""
								if item.passport_expiry_date?
									passport_expiry_string = dateFormat (new Date item.passport_expiry_date), sita_date_format_string
								if item.date_of_birth?
									birthday_string = dateFormat (new Date item.date_of_birth), sita_date_format_string								

								csvGenerator.add new SitaAirCarrierRecord "P", item.nationality_rcd, item.passport_number, passport_expiry_string, null, item.lastname, item.firstname,	birthday_string, item.gender_type_rcd, item.nationality_rcd, travel_type, null, null
								cb()
							, () ->
								#generate file name
								file_name = getSitaFileName data.flight_no, data.dep_date

								# save csv file
								robot.logger.debug "starting generate target file #{file_name}"
								csvGenerator.commit file_name, (writeErr) ->
									if writeErr?
										robot.logger.error "csv file write error: #{writeErr}"
										robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, "file #{file_name}"
									else
										robot.logger.info "file #{file_name} saved"