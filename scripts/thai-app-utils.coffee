# thai-app-utils.coffee

{thaiAppScheduleCoordinator} = require './lib/thaiapp-schedule-coordinator'
moment = require 'moment'
fs = require 'fs'
config = require 'app-config'
{log} = require './lib/vair-logger'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'
dateFormat = require 'dateformat'

wrapErrorMessage = (msg) ->
	return "Oops! Send passenger manifest to SITA fail! Error Reason:#{msg}"


getSitaFileName = (flight_no, dep_date) ->
	partial_file_name_format = "yyyymmdd"
	avantik_dateformat_string = "YYYYMMDD"
	depDateOri = moment(dep_date, avantik_dateformat_string).toDate()
	return "ZV#{flight_no}#{dateFormat depDateOri, partial_file_name_format}.csv"

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
checkAndWaitFileGenerate = (file_name, timeout, callback) ->
	path = config.avantik.SITA_CSV_FILE_PATH
	if timeout <= 0
		callback "file not exist"
	try 
		stat = fs.statSync path + file_name
		if stat?
			log.info "file status: #{JSON.stringify stat}"
			callback null
	catch 
		log.warning "file #{file_name} not exist yet, wait for 5 mins and retry" 
		setTimeout ()->
			checkAndWaitFileGenerate file_name, (timeout - 300), callback
		, 300000


module.exports = {
	wrapErrorMessage, getSitaFileName, sitaScheduleHouseKeeping, checkAndWaitFileGenerate
}