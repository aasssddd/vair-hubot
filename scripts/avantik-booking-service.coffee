# avantik-booking-service.coffee
# Description:
#   test web service.
#
# Commands:
#   hubot avantik describe booking service
# Notes:
#   web service to call avantik web service

soap = require 'soap'
{parseString} = require 'xml2js'

url = "http://vairtest.tikaero.com/tikAeroWebAPI/BookingService.asmx?WSDL"

describeMethods = (res) ->
	console.log "Roger in describeMethods"
	soap.createClient url, (err, client) ->
		if err
			res.reply "Err! #{JSON.stringify err, null, 4}"
		parseString client.describe(), (err, result) ->
			if err
				res.reply JSON.stringify err, null, 4 
			res.reply JSON.stringify result, null, 4


module.exports = (robot) ->
	robot.respond /describe avantik booking service/i, (res) ->
		res.reply "Roger!"
		console.log "Roger"
		describeMethods res
