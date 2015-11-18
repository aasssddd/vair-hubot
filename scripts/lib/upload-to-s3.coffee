# upload-to-s3.coffee
AWS = require 'aws-sdk'
fs = require 'fs'
path = require 'path'
{EventEmitter} = require 'events'
tosource = require 'tosource'

class S3FileAccessHelper
	
	AWS.config.loadFromPath './AWS.config'
	@bucket = "thaiapplog"

	###
		opts: 
			{
				target_bucket: 'thaiapplog' -- default
				target_path: '.' -- path under bucket
				target_name: '' -- same as source file name

			}
	###
	@UploadFile: (filePath, opts, callback) ->
		if typeof opts is 'function' and callback is undefined
			callback = opts
			opts = null
		
		option = opts ? 
			target_bucket: @bucket
			target_path: '.'
			target_name: path.basename filePath

		fs.exists filePath, (exist) ->
			if not exist
				callback "file not exist"

		data = fs.createReadStream filePath
		.on 'error', (err) ->
			return callback err
		.on 'open', () ->
			console.log "data: \n #{tosource data}"
			param = 
				Bucket: option.target_bucket
				Key: option.target_name
				Body: data
			s3obj = new AWS.S3
			s3obj.putObject param, (err, data) ->
				if err?
					console.log "err! #{tosource err}"
					callback err
				else
					callback err, data


module.exports.S3FileAccessHelper = S3FileAccessHelper