# slack-file-poster.coffee

###
		fileName: file to be upload
		channel: post to what channel
		callback: callback method
###
FormData = require 'form-data'
fs = require 'fs'
config = require 'app-config'
Logger = require('vair_log').Logger
async = require 'async'
request = require 'request'
tosource = require 'tosource'
path = require 'path'

postFileToSlack = (fileName, channel, callback)->
	log = Logger.getLogger()
	slackFileUploadEndpoint = "https://slack.com/api/files.upload"
	filePath = path.resolve config.avantik.SITA_CSV_FILE_PATH, fileName
	log.info "file path is #{filePath}"

	form = 
		"token": config.avantik.SLACK_FILE_UPLOAD_TOKEN
		"file": fs.createReadStream filePath
		"channels": "#{channel}"

	setTimeout () ->
		log.debug "upload file: #{filePath} to channel #{form.channels}"
		request.post { url: slackFileUploadEndpoint, formData: form }, (err, httpResp, body) ->
			if err?
				log.error "http post error: #{err}"
				callback err, null
			else
				log.debug "slack file upload result json #{JSON.stringify body}"
				callback null, body
	, 500


module.exports.postFileToSlack = postFileToSlack


