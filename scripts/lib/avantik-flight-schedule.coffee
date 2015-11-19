# avantik-flight-schedule.coffee

config = require 'app-config'
soap = require 'soap'
dateFormat = require 'dateformat'
{parseString} = require 'xml2js'
tosource = require 'tosource'
Log = require 'log'
async = require 'async'

###
	data:
		fdate: yyyymmdd
		flight: flight number
###

getFlightSchedule = (data, callback) ->
	level = process.env.HUBOT_LOG_LEVEL
	if not level?
		level = "info"

	log = new Log(level)
	errMsg = ""
	schedule_api_url = config.avantik.AVANTIK_FLIGHT_ENDPOINT
	dataFormatString = "yyyymmdd"

	flights = []

	log.info "input parameter is #{tosource data}"

	if data.flight? 
		flights.push data.flight 
	else 
		flights = config.avantik.AVANTIK_QUERY_FLIGHT.split(";").map (val) -> val

	# query schedule
	soap.createClient schedule_api_url, (err, client) ->
		if err?
			errMsg = "service connect #{err}"
		else
			flight_data = []
			async.forEachOf flights, (item, key, cb) ->
				options = 
					flight: item
					fdate: data.date
				log.info "start querying flight schedule of #{tosource options}"
				args = 
					dtFlightFrom: options.fdate
					dtFlightTo: options.fdate
					FlightNumber: options.flight
				
				client.GetFlightInformationDeparture args, (qryErr, result) ->
					log.debug "request: \n#{client.lastRequest}"
					log.debug "response: \n#{client.lastResponse}"
					# parse result and return
					if qryErr?
						errMsg = "Query Error #{qryErr}"
					else
						parseString result.GetFlightInformationDepartureResult, (err, data) ->
							if err?
								callback err, flight_data
							else
								flight_data.push data
								log.info "one data record proceed"
								cb()
				
			,() ->
				log.info "data collected #{JSON.stringify flight_data}"
				callback errMsg, flight_data



module.exports.getFlightSchedule = getFlightSchedule