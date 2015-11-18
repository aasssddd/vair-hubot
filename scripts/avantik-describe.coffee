# avantik-booking-service.coffee
# Description:
#   avantik 
# Commands:
#   hubot describe me avantik service <service name>
# Notes:
#   web service to call avantik web service

soap = require 'soap'
{parseString} = require 'xml2js'
{AvantikInitBean} = require './lib/avantik-bean'

module.exports = (robot) ->
	robot.respond /describe me avantik service\s*(.*)?$/i, (res) ->
		describeMethods res

describeMethods = (res) ->
	initBean = new AvantikInitBean()
	soap.createClient initBean.url, (err, client) ->
		if err
			res.reply "Err! #{JSON.stringify err, null, 4}"
		else
			if res.match[1]
				res.reply JSON.stringify client.describe().BookingService.BookingServiceSoap[res.match[1]], null, 4
			else 
				res.reply JSON.stringify client.describe()
			

