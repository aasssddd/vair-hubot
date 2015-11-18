# avantik-service-init.coffee
# Description:
#   avantik service init module
# Commands:
#	hubot avantik service initialize
# Notes:
#   web service to call avantik web service

soap = require 'soap'
{parseString} = require 'xml2js'
{AvantikInitBean} = require './lib/avantik-bean'

module.exports = (robot) ->
	robot.respond /avantik service initialize/i, (res) ->
		initReq = new AvantikInitBean() 
		soapRes = soap.createClient initReq.url, (err, client) ->
			if err
				res.reply "Err! #{err}"

			serviceInitialize client, initReq, (err, soapResult) ->
				if err?
					res.reply "Err: #{err}"
				else 
					console.log JSON.stringify soapResult, null, 41
					if "000" in soapResult.error.code
						console.log "OK, #{soapResult.error.message}"
					else
						res.reply "Not OK, #{soapResult.error.code} #{soapResult.error.message}"

# initialize service
serviceInitialize = (client, req, callback) ->

	client.ServiceInitialize req, (err, result) ->
		if err?
			console.log "request: #{client.lastRequest}"
			console.log "response: #{client.lastResponse}"
			console.log "response header: #{JSON.stringify client.lastResponseHeaders}"
			callback err, result
		else
			parseString result.ServiceInitializeResult, (err, parseResult) ->
				callback err, parseResult

module.exports.serviceInitialize = serviceInitialize