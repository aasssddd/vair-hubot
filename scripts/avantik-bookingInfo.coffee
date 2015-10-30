# avantik-booking-service.coffee
# Description:
#   avantik 
#	need config 
#		AVANTIK_ENDOPINT - 
#		AVANTIK_USER_ACCOUNT - 
#		AVANTIK_USER_PASSWORD - 
#		AVANTIK_AGENCY_CODE - 
#		AVANTIK_LANGUAGE_CODE
# Commands:
#   hubot describe me avantik service <service name>
#	hubot avantik service initialize
# Notes:
#   web service to call avantik web service

soap = require 'soap'
{parseString} = require 'xml2js'


url = process.env.AVANTIK_ENDPOINT ? "http://vairtest.tikaero.com/tikAeroWebAPI/BookingService.asmx?WSDL"

module.exports = (robot) ->
	robot.respond /describe me avantik service\s*(.*)?$/i, (res) ->
		describeMethods res

	robot.respond /avantik service initialize/i, (res) ->
		soap.createClient url, (err, client) ->
			if err
				console.log "Err! #{err}"
				res.reply serviceInitialize(client)

	robot.respond /avantik get passenger manifest of flight\s*(.*)? on date\s*(.*)$/i, (res) ->
		soap.createClient url, (err, client) ->
			if err? 
				res.reply "err! #{JSON.stringify err, null, 4}"
			else
				auth = serviceInitialize client
				console.log JSON.stringify auth
				args = 
					airline_rcd : "zv"
					flight_number : res.match[1]
					departure_date_from : res.match[2]
				output = getPassengerManifest args, client
				console.log JSON.stringify output
				res.reply JSON.stringify output


describeMethods = (res) ->
	console.log "Endpoint: #{url}"
	soap.createClient url, (err, client) ->
		if err
			res.reply "Err! #{JSON.stringify err, null, 4}"
		else
			if res.match[1]
				console.log client.describe().BookingService.BookingServiceSoap.GetActivities
				res.reply JSON.stringify client.describe().BookingService.BookingServiceSoap[res.match[1]], null, 4
			else 
				res.reply JSON.stringify client.describe(), null, 4
			

# initialize service
serviceInitialize = (client) ->
	console.log "Endpoint: #{url}"
	console.log "Agency: #{process.env.AVANTIK_AGENCY_CODE}"
	console.log "User Account: #{process.env.AVANTIK_USER_ACCOUNT}"
	console.log "User Password: #{process.env.AVANTIK_AGENCY_CODE}"
	args = 
		strAgencyCode:	process.env.AVANTIK_AGENCY_CODE ? "default"
		strUserName:	process.env.AVANTIK_USER_ACCOUNT ? "default"
		strPassword:	process.env.AVANTIK_USER_PASSWORD ? "default"
		strLanguageCode:	process.env.AVANTIK_LANGUAGE_CODE ? "ZH"
	client.ServiceInitialize args, (err, result) ->
		if err
			err
		result

getPassengerManifest = (args, client) ->
	args = 
		airline_rcd : args.airline_rcd ? "zv"
		flight_number : args.flight_number
		departure_date_from : args.departure_date_from
	client.GetPassengerManifest args, (err, result) ->
		if err?
			err
		result

