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

module.exports = (robot) ->
	robot.respond /describe avantik booking service/i, (res) ->
		res.reply "Roger!"

