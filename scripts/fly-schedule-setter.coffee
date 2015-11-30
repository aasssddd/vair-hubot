# fly-schedule-setter.coffee

config = require 'app-config'
string = require 'string'
getFlightSchedule = require './lib/avantik-flight-schedule'
moment = require 'moment'
ThaiAppScheduleCoordinator = require './lib/thaiapp-schedule-coordinator'
SendToSita = require './lib/sita-sender'


module.exports = (robot) ->

	robot.on 'SendSitaSchedule', () ->
		qry_date = moment().format("YYYYMMDD")
		args = 
			fdate: qry_date

		robot.logger.info "retriveSchedule with params #{qry_date}"

		getFlightSchedule args, (err, res) ->
			#run job 3 hours earlier before departure
			job_trigger_offset_hour = config.avantik.SITA_SEND_TIME_SHIFT
			if err != ""
				robot.logger.error "Err #{err}"
				robot.send "Err #{err}"
			else
				# set schedule task 
				res.forEach (item) ->
					flightDetail = item.Flights.Details[0]
					data = 
						flight_no: flightDetail.flight_number[0]
						dep_date: flightDetail.departure_date[0].split(" ")[0]
						dep_time: string(flightDetail.planned_departure_time[0]).padLeft(4, "0").toString()
						arr_date: flightDetail.arrival_date[0].split(" ")[0]
						arr_time: string(flightDetail.planned_arrival_time[0]).padLeft(4, "0").toString()

					robot.logger.info "JOB Request data is: #{tosource data}"
					partial_file_name_format = "yyyymmdd"
					avantik_dateformat_string = "YYYYMMDD"
					depDateOri = moment(data.dep_date, avantik_dateformat_string).toDate()
					file_name = "ZV#{flight_num}#{dateFormat depDateOri, partial_file_name_format}.csv"

					# set sechedule
					schedule_date = moment data.dep_date.split(" ")[0], "YYYYMMDD"
					schedule_time = data.dep_time.toString().match /.{1,2}/g
					schedule_date.hour schedule_time[0]
					schedule_date.minute schedule_time[1]
					schedule_date.add job_trigger_offset_hour, 'hour'
					robot.logger.info "JOB is scheduled at #{schedule_date.toDate()}"
					robot.messageRoom config.avantik.AVANTIK_MESSAGE_ROOM, "Passenger data of flight ZV#{data.flight_no} will be send at #{schedule_date.toDate()}"
					ThaiAppScheduleCoordinator.addSitaScheduleJob schedule_date.toDate(), ((obj) ->

						#send file to sita at scheduled time
						SendToSita "#{file_name}"

						# after sent, canceling today's send job
						ThaiAppScheduleCoordinator.cancelSitaScheduleJob data.flight_no
						).bind null, data