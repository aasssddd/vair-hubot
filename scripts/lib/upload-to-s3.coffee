# upload-to-s3.coffee
AWS = require 'aws-sdk'
fs = require 'fs'
path = require 'path'
{EventEmitter} = require 'events'
tosource = require 'tosource'
Log = require 'log'

class S3FileAccessHelper

	AWS.config.loadFromPath './AWS.config'
	@bucket = "thaiappdata"

	###
		opts: 
			{
				target_bucket: 'thaiappdata' -- default
				target_path: '.' -- path under bucket
				target_name: '' -- same as source file name
			}
	###
	@UploadFile: (filePath, opts, callback) ->
		level = process.env.HUBOT_LOG_LEVEL
		if not level?
			level = "info"

		log = new Log(level)

		if typeof opts is 'function' and callback is undefined
			callback = opts
			opts = null
		
		option = opts ? 
			target_bucket: @bucket
			target_path: '.'
			target_name: path.basename filePath

		fs.exists filePath, (exist) ->
			if not exist
				log.error "file not exist"
				callback "file not exist"

		data = fs.createReadStream(filePath)
		.on 'error', (err) ->
			log.error "create read stream error"
			return callback err
		.on 'open', () ->

			param = 
				Bucket: option.target_bucket
				Key: option.target_name
				Body: data

			s3obj = new AWS.S3
			s3obj.putObject param, (err, data) ->
				if err?
					log.error "data upload fail with message #{err}"
					callback err
				else
					callback err, data


module.exports.S3FileAccessHelper = S3FileAccessHelper