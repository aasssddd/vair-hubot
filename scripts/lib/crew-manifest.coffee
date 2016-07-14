# crew-manifest.coffee

request = require 'request'
config = require 'app-config'
{parseString} = require 'xml2js'
tosource = require 'tosource'
Logger = require('vair_log').Logger

module.exports.GetCrewManifest = (flight_no, date, callback) ->
	log = Logger.getLogger()
	form = 
		user: config.arrangement.USER
		flight_no: flight_no
		date: date

	setTimeout ()->
		request.post { url: config.arrangement.URL, formData: form }, (err, httpResp, body) ->
				if err?
					log.error "http post error: #{err}"
					callback err, null
				else
					log.debug "slack file upload result json #{JSON.stringify body}"
					parseString body, (parseErr, data) ->
						if parseErr?
							callback parseErr, null
						else
							log.info "parsed crew manifest #{tosource data}"
							callback parseErr, data
	, 500