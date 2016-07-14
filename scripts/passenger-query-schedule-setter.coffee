# passenger-query-schedule-setter.coffee

tosource = require 'tosource'
soap = require 'soap'
Cookie = require 'soap-cookie'
moment = require 'moment'
dateFormat = require 'dateformat'
async = require 'async'
config = require 'app-config'
lookup = require 'country-code-lookup'
Logger = require('vair_log').Logger
{serviceInitialize} = require './avantik-service-init'
{getPassengerManifest} = require './avantik-customer-info'
{AvantikInitBean, PassengerManifestReq} = require './lib/avantik-bean'
{SitaAirCarrierCSV, SitaAirCarrierRecord} = require './lib/sita-csv-generator'
{postFileToSlack} = require './lib/slack-file-poster'
{wrapErrorMessage, getSitaFileName} = require './thai-app-utils'

module.exports = (robot) ->
	log = Logger.getLogger()
	###
		data:
			flight_no: flight number
			dep_date: YYYYMMDD
			dep_time: HHMM
			arr_date: YYYYMMDD
			arr_time: HHMM
	###
	robot.on 'sendPassengerInfo', (data, cb) ->

		log.info "query passenger info of flight #{data.flight_no}"
		log.debug "query passenger info with parameters: #{tosource data}"
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
						log.error "Err: #{initErr}" 
						robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, wrapErrorMessage "#{initErr}"

					else if "000" not in initResult.error.code
						robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, wrapErrorMessage "#{initResult.error.code} #{initResult.error.message}"

					else
						log.debug "request: #{client.lastRequest}"
						log.debug "response: #{client.lastResponse}"
						log.debug "Init OK, #{initResult.error.code} #{initResult.error.message}"
						cookie = new Cookie(client.lastResponseHeaders)
						log.debug "Cookie: #{JSON.stringify cookie}"

						# set cookie
						client.setSecurity(cookie)

						# get passengers manifest
						args = new PassengerManifestReq()
						args.PassengersManifestRequest.airline_rcd = "ZV"
						args.PassengersManifestRequest.flight_number = data.flight_no
						args.PassengersManifestRequest.departure_date_from = moment(data.dep_date, avantik_dateformat_string).format avantik_date_req_string

						getPassengerManifest args, client, (passErr, passResult) ->
							if passErr?
								robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, wrapErrorMessage "err! #{JSON.stringify passErr}"
							else
								log.debug "request header: #{JSON.stringify client.lastRequestHeaders}"
								log.debug "request: #{client.lastRequest}"
								log.debug "response: #{client.lastResponse}"

							# convert into SITA file format
							if !passResult? && !passResult.root?
								log.debug "no data result message is: #{tosource passResult}"
								robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, "no passenger data found on flight #{data.flight_no} at #{data.dep_date}"
								return

							flightInfo = passResult.root.Flight[0]

							if !flightInfo
								log.debug "no data result message is: #{tosource passResult}"
								robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, "no flight found"
								return
							
							sita_date_format_string = "dd-mmm-yyyy"

							# assume all passengers are Normal
							travel_type = "N"
							log.debug "flight info: #{tosource flightInfo}"
							depDateOri = moment(data.dep_date, avantik_dateformat_string).toDate()
							arrDateOri = moment(data.arr_date, avantik_dateformat_string).toDate()
							depDate = dateFormat depDateOri, sita_date_format_string
							depTime = data.dep_time
							arrDate = dateFormat arrDateOri, sita_date_format_string
							arrTime = data.arr_time
							flight_num = flightInfo.airline_rcd + flightInfo.flight_number
							

							# put passenger data
							passengerData = []
							if flightInfo.Passenger?
								flightInfo.Passenger.forEach (item) ->
									if passengerData.indexOf item <= -1
										passengerData.push item

							max_records_of_file_part = config.avantik.MAX_RECORD_COUNT_PER_FILE

							if passengerData.length > 0
								file_split = passengerData.length // max_records_of_file_part + (if passengerData.length % max_records_of_file_part > 0 then 1 else 0)
								file_part = []


								# slice passenger data by max record count
								for cnt in [0..file_split-1]
									startIndex = cnt * max_records_of_file_part
									endIndex = if startIndex + max_records_of_file_part > passengerData then passengerData.length - 1 else startIndex + max_records_of_file_part - 1
									file_part.push passengerData[startIndex..endIndex]


								# generate file
								file_part.forEach (pnrs, index) ->
									csvGenerator = new SitaAirCarrierCSV flight_num, flightInfo.origin_rcd, depDate, depTime, flightInfo.destination_rcd, arrDate, arrTime

									pnrs.forEach (pnr) ->
										log.debug "passenger: #{JSON.stringify pnr}"
										passport_expiry_string = null
										birthday_string = ""
										if pnr.passport_expiry_date?
											passport_expiry_string = dateFormat (new Date pnr.passport_expiry_date), sita_date_format_string
										if pnr.date_of_birth?
											birthday_string = dateFormat (new Date pnr.date_of_birth), sita_date_format_string								
										nationality_iso3 = null
										if pnr.nationality_rcd? && pnr.nationality_rcd != undefined
											nationality_iso3 = lookup.byIso(pnr.nationality_rcd[0]).iso3

										csvGenerator.add new SitaAirCarrierRecord "P", nationality_iso3, pnr.passport_number, passport_expiry_string, nationality_iso3, pnr.lastname, pnr.firstname,	birthday_string, pnr.gender_type_rcd, nationality_iso3, travel_type, null, null

									#generate file name
									file_part_postfix = if file_part.length is 1 then "" else "_part#{index}"

									file_name = getSitaFileName data.flight_no, data.dep_date, file_part_postfix

									# save csv file
									log.debug "starting generate target file #{file_name}"
									csvGenerator.commit file_name, (writeErr) ->
										if writeErr?
											log.error "csv file write error: #{writeErr}"
											robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, "file #{file_name}"
											if cb?
												return cb writeErr
										else
											log.info "file #{file_name} saved"
									
								if cb?
									return cb()

										
								