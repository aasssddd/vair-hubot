# sita-csv-generator.coffee

csvWriter = require 'csv-write-stream'
fs = require 'fs'

###
	record for generate SitaAirCarrierCSV 
###
class SitaAirCarrierRecord

	constructor: (@DocumentType, @Nationality, @DocumentNumber, @DocumentExpiryDate, @IssuingState, @FamilyName, @GivenName, 	@DateofBirth, @Sex, @CountryofBirth, @TravelType, @Override, @Response) ->

	@arrayOf: (record)->
		data = [record.DocumentType, record.Nationality, record.DocumentNumber, record.DocumentExpiryDate, record.IssuingState, record.FamilyName, record.GivenName, record.DateofBirth, record.Sex, record.CountryofBirth, record.TravelType, record.Override, record.Response]
		return data

###
	options: 
		type: 
			C - Operating Crew
			X - Positioning Crew
			P - Passenger
		service:
			*FLIGHT - for Airlines
			*AIRCRAFT - for General Aviation Carriers
			*VESSEL – for Maritime Carriers
	serviceValue: Flight Number
	depDate,
	depTime,
	arrPort,
	arrDate,
	arrTime
###
class SitaAirCarrierCSV
	data = []
	filePath = "./"

	constructor: (flightNum, depPort, depDate, depTime, arrPort, arrDate, arrTime, options) ->
		opts = options ?
			version: "***VERSION 4"
			batch: "APP"
			type: "P"
			direction: "I"
			service: "*FLIGHT"


		data.push new SitaAirCarrierRecord(opts.version)
		data.push new SitaAirCarrierRecord("*** HEADER")
		data.push new SitaAirCarrierRecord("*** BATCH", opts.batch)
		data.push new SitaAirCarrierRecord("*TYPE", opts.type)
		data.push new SitaAirCarrierRecord("*DIRECTION", opts.direction)
		data.push new SitaAirCarrierRecord(opts.service, flightNum)
		data.push new SitaAirCarrierRecord("*DEP PORT", depPort)
		data.push new SitaAirCarrierRecord("*DEP DATE", depDate)
		data.push new SitaAirCarrierRecord("*DEP TIME", depTime)
		data.push new SitaAirCarrierRecord("*ARR PORT", arrPort)
		data.push new SitaAirCarrierRecord("*ARR DATE", arrDate)
		data.push new SitaAirCarrierRecord("*ARR TIME", arrTime)
		data.push new SitaAirCarrierRecord("*TB PORT", "")
		data.push new SitaAirCarrierRecord("*TB DATE", "")
		data.push new SitaAirCarrierRecord("*TB TIME", "")
		data.push new SitaAirCarrierRecord()
		data.push new SitaAirCarrierRecord("***START")

	add: (record) ->
		data.push record

	commit: (fileName) ->
		data.push new SitaAirCarrierRecord("***END")

		file = []
		data.forEach (objIns) ->
			file.push SitaAirCarrierRecord.arrayOf objIns

		writer = csvWriter({headers : ["DocumentType", "Nationality", "DocumentType", "DocumentExpiryDate", 
			"IssuingState", "FamilyName", "GivenName", "DateofBirth", "Sex", "CountryofBirth", "TravelType", 
			"Override", "Response"]})
		writer.pipe(fs.createWriteStream filePath + fileName)
		file.forEach (obj) ->
			writer.write obj
		writer.end

module.exports.SitaAirCarrierRecord = SitaAirCarrierRecord
module.exports.SitaAirCarrierCSV = SitaAirCarrierCSV