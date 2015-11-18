# avantik-flight-schedule.coffee

config = require 'app-config'
soap = require 'soap'
dateFormat = require 'dateformat'
{parseString} = require 'xml2js'
tosource = require 'tosource'
deasync = require 'deasync'


getFlightSchedule = (date, callback) ->
	wait_async_exec = 5000
	errMsg = ""
	schedule_api_url = config.avantik.AVANTIK_FLIGHT_ENDPOINT
	dataFormatString = "yyyymmdd"
	flights = config.avantik.AVANTIK_QUERY_FLIGHT.split(";").map (val) -> val
	# query schedule
	
	soap.createClient schedule_api_url, (err, client) ->
		if err?
			errMsg = "service connect #{err}"
		else
			flight_data = []
			for f in flights
				options = 
					flight: f
					fdate: (dateFormat date, dataFormatString)

				args = 
					dtFlightFrom: options.fdate
					dtFlightTo: options.fdate
					FlightNumber: options.flight

				client.GetFlightInformationDeparture args, (qryErr, result) ->
					# parse result and return
					if qryErr?
						errMsg = "Query Error #{qryErr}"
					else
						parseString result.GetFlightInformationDepartureResult, (err, data) ->
							if err?
								callback err, flight_data
							else
								flight_data.push data

			deasync.sleep wait_async_exec

			callback errMsg, flight_data
	


module.exports.getFlightSchedule = getFlightSchedule