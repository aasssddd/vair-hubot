# sita-sender.coffee

###
	send file to sita
###
config = require 'app-config'
fs = require 'fs'
{log} = require './vair-logger'
module.exports.SendToSita = (file_name, callback) ->
	file_path = config.avantik.SITA_CSV_FILE_PATH
	log.info "start sending file #{file_path}#{file_name}"
	file_full_path = file_path + file_name
	log.warning "not implemented!"
	callback null