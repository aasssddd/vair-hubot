# avantik-booking-service.coffee
# Description:
#   avantik 
# Commands:
#   hubot describe me avantik service <service name>
#	hubot avantik service initialize
# Notes:
#   web service to call avantik web service

soap = require 'soap'
{parseString} = require 'xml2js'
{AvantikInitBean} = require './avantik-bean'


url = process.env.AVANTIK_ENDPOINT ? "http://vairtest.tikaero.com/tikAeroWebAPI/BookingService.asmx?WSDL"

module.exports = (robot) ->
	robot.respond /describe me avantik service\s*(.*)?$/i, (res) ->
		describeMethods res

	robot.respond /avantik service initialize/i, (res) ->
		soap.createClient url, (err, client) ->
			if err
				console.log "Err! #{err}"
			robot.reply "#{serviceInitialize client}"

	robot.respond /avantik get passenger manifest of flight\s*(.*)? on date\s*(.*)$/i, (res) ->
		soap.createClient url, (err, client) ->
			if err? 
				res.reply "err! #{JSON.stringify err, null, 4}"
			else
				auth = serviceInitialize new ServiceInitializeReq(), client
				if !auth
					res.reply "err!!!!"
				args = 
					airline_rcd : "zv"
					flight_number : res.match[1]
					departure_date_from : res.match[2]
				output = getPassengerManifest args, client
				return {
					output 
				}


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
serviceInitialize = (arg, client, res) ->
	req = new AvantikInitBean()
	args = 
		strAgencyCode:	req.url
		strUserName:	req.account
		strPassword:	req.password
		strLanguageCode:	req.language
	res.send "Req: #{JSON.stringify args}"
	client.ServiceInitialize args, (err, result) ->
		if err?
			return { err }
		parseResult = parseString result.ServiceInitializeResult, (err, parseResult) ->
			console.log parseResult
			if parseResult.error.code != '000'
				console.log parseResult.message
				return false
			return true

getPassengerManifest = (args, client, res) ->
	args = 
		airline_rcd : args.airline_rcd ? "zv"
		flight_number : args.flight_number
		departure_date_from : args.departure_date_from
	client.GetPassengerManifest args, (err, result) ->
		if err?
			err
		console.log result
		res.reply result

