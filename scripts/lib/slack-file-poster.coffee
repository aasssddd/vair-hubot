# slack-file-poster.coffee

###
		filePath: file to be upload
		channel: post to what channel
		callback: callback method
###
FormData = require 'form-data'
fs = require 'fs'
config = require 'app-config'
Log = require 'log'
async = require 'async'
request = require 'request'
tosource = require 'tosource'

postFileToSlack = (filePath, channel, callback)->
	slackFileUploadEndpoint = "https://slack.com/api/files.upload"

	level = process.env.HUBOT_LOG_LEVEL
	if not level?
		level = "info"

	log = new Log(level)

	form = 
		"token": config.avantik.SLACK_FILE_UPLOAD_TOKEN
		"file": fs.createReadStream filePath
		"channels": "#{channel}"

	log.debug "upload content\ntoken: #{config.avantik.SLACK_FILE_UPLOAD_TOKEN}\n#{filePath}\n#{channel}"

	request.post { url: slackFileUploadEndpoint, formData: form }, (err, httpResp, body) ->
		if err?
			log.error "http post error: #{err}"
			callback err, null
		else
			log.info "slack file upload result json #{JSON.stringify body}"
			callback null, body


module.exports.postFileToSlack = postFileToSlack


