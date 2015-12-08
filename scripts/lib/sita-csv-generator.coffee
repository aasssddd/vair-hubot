# sita-csv-generator.coffee

csv = require "fast-csv"
fs = require 'fs'
async = require 'async'
{log} = require './vair-logger'
tosource = require 'tosource'
config = require 'app-config'
csvWriter = require 'csv-write-stream'
moment = require 'moment'


###
	record for generate SitaAirCarrierCSV 
###
class SitaAirCarrierRecord

	constructor: (
		@DocumentType = "P", 
		@Nationality = "TWN", 
		@DocumentNumber = "11111111", 
		@DocumentExpiryDate = moment("2200/12/31", "YYYY/MM/DD").format("DD-MMM-YYYY"), 
		@IssuingState = @Nationality, 
		@FamilyName, 
		@GivenName, 
		@DateofBirth = moment("1991/03/12", "YYYY/MM/DD").format("DD-MMM-YYYY"), 
		@Sex, 
		@CountryofBirth = "TWN", 
		@TravelType = "N", 
		@Override, 
		@Response) ->


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

	filePath = config.avantik.SITA_CSV_FILE_PATH

	constructor: (flightNum, depPort, depDate, depTime, arrPort, arrDate, arrTime, options) ->
		@data = []
		opts = options ?
			version: "***VERSION 4"
			batch: "APP"
			type: "P"
			service: "*AIRCRAFT"

		direction = if "#{arrPort}" is "TPE" then "O" else "I"

		@data.push new SitaAirCarrierRecord opts.version, "", "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "***HEADER", "", "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "***BATCH", opts.batch, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*TYPE", opts.type, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*DIRECTION", direction, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord opts.service, flightNum, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*DEP PORT", depPort, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*DEP DATE", depDate, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*DEP TIME", depTime, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*ARR PORT", arrPort, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*ARR DATE", arrDate, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*ARR TIME", arrTime, "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*TB PORT", "", "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*TB DATE", "", "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "*TB TIME", "", "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "", "", "", "", "", "", "", "", "", "", "", "", ""
		@data.push new SitaAirCarrierRecord "***START", "", "", "", "", "", "", "", "", "", "", "", ""

	add: (record) ->
		@data.push record


	commit: (fileName, callback) ->

		@data.push new SitaAirCarrierRecord "***END", "", "", "", "", "", "", "", "", "", "", "", ""

		file = []
		@data.forEach (objIns) ->
			file.push SitaAirCarrierRecord.arrayOf objIns

		writer = csvWriter({headers : ["Document Type", "Nationality", "Document Number", "Document Expiry Date", 
			"Issuing State", "Family Name", "Given Names", "Date of Birth", "Sex", "Country of Birth", "Travel Type", 
			"Override", "Response"]})
		writer.pipe(fs.createWriteStream filePath + fileName)

		writer.on 'finish', ()->
			file = []
			@data = []
			log.debug "file saved!"
			callback()

		file.forEach (item) ->
			writer.write item, () ->
				log.debug "record: #{JSON.stringify item} is written"
		writer.end()
			

module.exports.SitaAirCarrierRecord = SitaAirCarrierRecord
module.exports.SitaAirCarrierCSV = SitaAirCarrierCSV