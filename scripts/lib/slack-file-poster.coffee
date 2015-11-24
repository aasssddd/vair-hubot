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
fetch = require 'node-fetch'
tosource = require 'tosource'

postFileToSlack = (filePath, channel, callback)->
	slackFileUploadEndpoint = "https://slack.com/api/files.upload"

	level = process.env.HUBOT_LOG_LEVEL
	if not level?
		level = "info"

	log = new Log(level)

	form = new FormData
	form.append "token", config.avantik.SLACK_FILE_UPLOAD_TOKEN
	form.append "file", fs.createReadStream filePath
	form.append "channels", "##{channel}"

	log.debug "upload content\ntoken: #{config.avantik.SLACK_FILE_UPLOAD_TOKEN}\n#{filePath}\n#{channel}"

	fetch slackFileUploadEndpoint, { method: "POST", body: form }
	.then (res) ->
		return res.json()
	.then (json) ->
		log.debug "slack file upload result json #{JSON.stringify json}"
		callback null, json


module.exports.postFileToSlack = postFileToSlack


