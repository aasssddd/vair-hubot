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

url = 'http://zvbookapisecure-test.avantik.io/TikAe	roWebAPI/BookingService.asmx?WSDL'

describeMethods = (res) ->
	soap.createClient url, (err, client) ->
		parseString client.describe(), (err, result) ->
			if err
				res.reply JSON.stringify err, null, 4 
			res.reply JSON.stringify result, null, 4


module.exports = (robot) ->
	robot.respond /describe avantik booking service/i, (res) ->
		describeMethods res
