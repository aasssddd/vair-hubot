# thai-app-utils.coffee

{thaiAppScheduleCoordinator} = require './lib/thaiapp-schedule-coordinator'
moment = require 'moment'
fs = require 'fs'
config = require 'app-config'
tosource = require 'tosource'
Logger = require('vair_log').Logger
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'
dateFormat = require 'dateformat'

log = Logger.getLogger()
wrapErrorMessage = (msg) ->
	return "Oops! Send passenger manifest to SITA fail! Error Reason:#{msg}"


getSitaFileName = (flight_no, dep_date, postfix) ->
	partial_file_name_format = "yyyymmdd"
	avantik_dateformat_string = "YYYYMMDD"	
	depDateOri = moment(dep_date, avantik_dateformat_string).toDate()
	file_name_postfix = if postfix? then postfix else ""

	return "ZV#{flight_no}#{dateFormat depDateOri, partial_file_name_format}#{file_name_postfix}.csv"

sitaScheduleHouseKeeping = () ->
	# reset job queue
	thaiAppScheduleCoordinator.cancelAllJobs()

	# check if folder exists?
	path = config.avantik.SITA_CSV_FILE_PATH

	fs.stat path, (err, stat) ->
		if err?
			# path not exist, create
			mkdirp.sync "#{path}"
		else 
			#Kill all files local
			rimraf.sync "#{path}"
			
			#Rebuild folder
			mkdirp.sync "#{path}"

###
	wait for file appear
###
checkAndWaitFileGenerate = (pattern, timeout, callback) ->

	if timeout <= 0
		callback "file not exist"
	try 
		files = fs.readdirSync config.avantik.SITA_CSV_FILE_PATH
		search_result = []
		if files?
			
			search_result = files.filter (file_name) ->
				match = file_name.indexOf pattern
				log.debug "check if #{file_name} matches #{pattern} ? #{match > -1}"
				return match > -1

			log.debug "file exist? #{search_result.length > 0}"

			if search_result.length > 0
				return callback null

		log.warn "file not exist, wait for 30 seconds and retry"
		setTimeout () ->
			checkAndWaitFileGenerate pattern, (timeout - 30), callback
		, 30000

	catch ex
		log.warn "directory not exist yet, wait for 30 seconds and retry"
		setTimeout ()->
			checkAndWaitFileGenerate pattern, (timeout - 30), callback
		, 30000


module.exports = {
	wrapErrorMessage, getSitaFileName, sitaScheduleHouseKeeping, checkAndWaitFileGenerate
}