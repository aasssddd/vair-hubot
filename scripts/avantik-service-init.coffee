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
Logger = require('vair_log').Logger

module.exports = (robot) ->
	log = Logger.getLogger()
	robot.respond /avantik service initialize/i, (res) ->
		initReq = new AvantikInitBean() 
		soapRes = soap.createClient initReq.url, (err, client) ->
			if err
				res.reply "Err! #{err}"

			serviceInitialize client, initReq, (err, soapResult) ->
				log.debug "request: #{client.lastRequest}"
				log.debug "response: #{client.lastResponse}"
				log.debug "response header: #{JSON.stringify client.lastResponseHeaders}"
				if err?
					res.reply "Err: #{err}"
				else 
					log.debug JSON.stringify soapResult, null, 41
					if "000" in soapResult.error.code
						log.debug "OK, #{soapResult.error.message}"
					else
						res.reply "Not OK, #{soapResult.error.code} #{soapResult.error.message}"

# initialize service
serviceInitialize = (client, req, callback) ->

	client.ServiceInitialize req, (err, result) ->
		if err?
			callback err, result
		else
			parseString result.ServiceInitializeResult, (err, parseResult) ->
				callback err, parseResult

module.exports.serviceInitialize = serviceInitialize