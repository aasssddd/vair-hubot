# sita-sender.coffee

###
	send file to sita
###
config = require 'app-config'
fs = require 'fs'
Logger = require('vair_log').Logger
path = require 'path'
Client = require('ssh2').Client
tosource = require "tosource"

module.exports.SendToSita = (file_name, callback) ->
	log = Logger.getLogger()
	ftp_retry_count = 5
	ftp_retry_interval = 60000
	file_path = path.resolve config.avantik.SITA_CSV_FILE_PATH, file_name
	file_uploaded = false
	target_path = "#{config.sita.DATA_STORE_PATH}/#{file_name}"

	conn = new Client()
	log.info "starting connect to ftp"

	conn.on "error", (err) ->
		log.info "SFTP Connect error, #{err}"
		callback err
	.on "timeout", ()->
		log.warn "[ftp] timeout"
	.on "close", (err) ->
		if file_uploaded
			return
		if ftp_retry_count < 1
			return callback "ftp connect error", null
		log.warn "[ftp] closed unexpected"
		ftp_retry_count--
		log.warn "retry left #{ftp_retry_count} times..."
		log.warn "wait #{ftp_retry_interval / 1000} seconds to reconnect..."
		con = this
		setTimeout ()->
			con.connect {
				host: config.sita.FTP_HOST,
				port: config.sita.FTP_PORT,
				username: config.sita.USER_NAME,
				password: config.sita.PASSWORD
			}
		, ftp_retry_interval
	.on "error", () ->
		log.warn "[ftp] error"
	.on "ready", ()->
		log.info "SFTP Client: ready"
		conn.sftp (conErr, sftp) ->
			if conErr? 
				log.error "SITA SFTP Connect Error"
				callback conErr
			else
				# start to write file
				fs.stat file_path, (fErr, stat) ->
					if fErr?
						log.error "error: #{fErr}"
						callback fErr, null
					else
						log.info "start to send file #{file_name} to #{config.sita.FTP_HOST}"
						log.info "path: #{target_path}"
						rStream = fs.createReadStream file_path
						wStream = sftp.createWriteStream target_path
						wStream.on "error", (err) ->
							log.error "file write error #{err}"
							callback err, null
						.on "close", ()->
							log.info "file uploaded!"
							file_uploaded = true
							callback()
						.on "data", (data)->
							log.info "writing #{data}"
						rStream.pipe wStream

	.connect {
		host: config.sita.FTP_HOST,
		port: config.sita.FTP_PORT,
		username: config.sita.USER_NAME,
		password: config.sita.PASSWORD,
	}

