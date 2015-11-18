# avantik-customer-info.coffee
# Description:
#   avantik get passenger info module
# Commands:
#	hubot avantik get passenger manifest of flight <flight no.> at <which date>
# Notes:
#   web service to call avantik web service

soap = require 'soap'
Cookie = require 'soap-cookie'
{parseString} = require 'xml2js'
{AvantikInitBean, PassengerManifestReq} = require './lib/avantik-bean'
{serviceInitialize} = require './avantik-service-init'
fs = require 'fs'

module.exports = (robot) ->
	robot.respond /avantik get passenger manifest of flight\s*(.*)? at\s*(.*)$/i, (res) ->
		initBean = new AvantikInitBean()
		soap.createClient initBean.url, (err, client) ->
			if err? 
				res.reply "err! #{err}"
			else
				serviceInitialize client, initBean, (err, initResult) ->
					if err?
						res.reply "err! #{err}"
					else if "000" not in initResult.error.code
						res.reply "Not OK, #{initResult.error.code} #{initResult.error.message}"
					else

						console.log "request: \n#{client.lastRequest}"
						console.log "response: \n#{client.lastResponse}"
						res.reply "Init OK, #{initResult.error.code} #{initResult.error.message}"
						cookie = new Cookie(client.lastResponseHeaders)
						console.log "Cookie: \n#{JSON.stringify cookie}"
						client.setSecurity(cookie)
						args = new PassengerManifestReq()
						args.PassengersManifestRequest.airline_rcd = "ZV"
						args.PassengersManifestRequest.flight_number = res.match[1]
						args.PassengersManifestRequest.departure_date_from = res.match[2]
						getPassengerManifest args, client, (passErr, passResult) ->
							if passErr?
								res.reply "err! #{JSON.stringify passErr}"
							else
								console.log "request header: \n#{JSON.stringify client.lastRequestHeaders}"
								console.log "request: \n#{client.lastRequest}"
								console.log "response: \n#{client.lastResponse}"
							fs.writeFile "avantik.log", JSON.stringify(passResult, null, 4), 'utf8', (werr) ->
							if werr?
								console.log "write err"
								res.reply "#{JSON.stringify passResult, null, 4}"

getPassengerManifest = (args, client, callback) ->
	req = 
		PassengersManifestRequest: args
	console.log JSON.stringify req, null, 4

	client.GetPassengerManifest args, (err, result) ->
		if err?
			callback err
		else
			parseString result.GetPassengerManifestResult, (err, parseResult) ->
				callback err, parseResult

module.exports.getPassengerManifest = getPassengerManifest