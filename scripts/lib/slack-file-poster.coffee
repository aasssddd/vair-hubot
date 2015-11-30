# slack-file-poster.coffee

###
		fileName: file to be upload
		channel: post to what channel
		callback: callback method
###
FormData = require 'form-data'
fs = require 'fs'
config = require 'app-config'
{log} = require './vair-logger'
async = require 'async'
request = require 'request'
tosource = require 'tosource'

postFileToSlack = (fileName, channel, callback)->
	slackFileUploadEndpoint = "https://slack.com/api/files.upload"
	filePath = config.avantik.SITA_CSV_FILE_PATH


	form = 
		"token": config.avantik.SLACK_FILE_UPLOAD_TOKEN
		"file": fs.createReadStream filePath + fileName
		"channels": "#{channel}"

	log.debug "upload contenttoken: #{config.avantik.SLACK_FILE_UPLOAD_TOKEN} #{filePath + fileName} #{channel}"

	request.post { url: slackFileUploadEndpoint, formData: form }, (err, httpResp, body) ->
		if err?
			log.error "http post error: #{err}"
			callback err, null
		else
			log.debug "slack file upload result json #{JSON.stringify body}"
			callback null, body


module.exports.postFileToSlack = postFileToSlack


