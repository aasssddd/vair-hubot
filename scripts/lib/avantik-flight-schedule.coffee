# avantik-flight-schedule.coffee

config = require 'app-config'
soap = require 'soap'
dateFormat = require 'dateformat'
{parseString} = require 'xml2js'
tosource = require 'tosource'
{log} = require './vair-logger'
async = require 'async'

###
	data:
		fdate: yyyymmdd
		flight: flight number
###

getFlightSchedule = (data, callback) ->

	errMsg = ""
	schedule_api_url = config.avantik.AVANTIK_FLIGHT_ENDPOINT
	dataFormatString = "yyyymmdd"

	flights = []

	log.debug "input parameter is #{tosource data}"

	if data.flight? 
		flights.push data.flight 
	else 
		flights = config.avantik.AVANTIK_QUERY_FLIGHT.split(";").map (val) -> val
		log.info "query flights #{flights}"

	# query schedule
	soap.createClient schedule_api_url, (err, client) ->
		if err?
			errMsg = "service connect #{err}"
		else
			flight_data = []
			async.forEachOf flights, (item, key, cb) ->
				options = 
					flight: item
					fdate: data.fdate
				log.info "start querying flight #{item} schedule data"
				log.debug "of #{tosource options}"
				args = 
					dtFlightFrom: options.fdate
					dtFlightTo: options.fdate
					FlightNumber: options.flight
				
				client.GetFlightInformationDeparture args, (qryErr, result) ->
					log.debug "request: #{client.lastRequest}"
					log.debug "response: #{client.lastResponse}"
					# parse result and return
					if qryErr?
						errMsg = "Query Error #{qryErr}"
					else
						parseString result.GetFlightInformationDepartureResult, (err, resData) ->
							if err?
								log.error "parse flight information data error : #{err}"
								callback err, flight_data
							else
								if resData? && resData.Flights.Details?
									flight_data.push resData
									log.debug "flight record proceed: #{resData.Flights.Details[0].flight_number[0]}"
								else
									log.warning "ZV#{args.FlightNumber}: no flight record found "
								cb()
			,() ->
				log.info "flight schedule data collected"
				log.debug "#{JSON.stringify flight_data}"
				callback errMsg, flight_data



module.exports.getFlightSchedule = getFlightSchedule