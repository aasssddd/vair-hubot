# avantik-booking-service.coffee
# Description:
#   test web service.
#
# Commands:
#   hubot avantik service describe
# Notes:
#   web service to call avantik web service

soap = require 'soap'
{parseString} = require 'xml2js'

url = "http://vairtest.tikaero.com/tikAeroWebAPI/BookingService.asmx?WSDL"

module.exports = (robot) ->
	robot.respond /avantik service describe/i, (res) ->
		describeMethods res

describeMethods = (res) ->
	soap.createClient url, (err, client) ->
		if err
			res.reply "Err! #{JSON.stringify err, null, 4}"
		console.log client.describe()
		parseString client.describe(), (err, result) ->
			if err
				res.reply "error #{JSON.stringify err, null, 4}" 
			res.reply JSON.stringify result, null, 4



