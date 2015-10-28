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
#   hubot avantik service describe
# Notes:
#   web service to call avantik web service

soap = require 'soap'
{parseString} = require 'xml2js'


url = process.env.AVANTIK_ENDPOINT | "http://vairtest.tikaero.com/tikAeroWebAPI/BookingService.asmx?WSDL"

module.exports = (robot) ->
	robot.respond /avantik service describe/i, (res) ->
		describeMethods res

	robot.respond /avantik service initialize/i, (res) ->
		parseString res, (err, result) ->
			res.reply JSON.stringify result, null, 4

describeMethods = (res) ->
	soap.createClient url, (err, client) ->
		if err
			res.reply "Err! #{JSON.stringify err, null, 4}"
		res.reply JSON.stringify client.describe(), null, 4
			

# initialize service
serviceInitialize = (client) ->
	args = 
		strAgencyCode:	process.env.AVANTIK_AGENCY_CODE
		strUserName:	process.env.AVANTIK_USER_ACCOUNT
		strPassword:	process.env.AVANTIK_USER_PASSWORD
		strLanguageCode:	process.env.AVANTIK_LANGUAGE_CODE
	client.ServiceInitialize args, (err, result) ->
		console.log result
		result
