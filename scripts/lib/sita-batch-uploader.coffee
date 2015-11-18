# sita-batch-uploader.coffee
###
	Upload batch file to sita
###

ftps = require 'ftps'


class SitaFTPHelper

	@uploadBatchFile: (opts, callback) ->

		options = 
			host: process.en ? ''
			username: 

		if typeof opts is 'function' and callback is undefined
			callback = opts
			opts = null
		options = opts ? 
			host: ''