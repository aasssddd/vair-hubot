# avantik-bean.coffee
config = require 'app-config'

class AvantikInitBean
	constructor: () ->
		@url = config.avantik.AVANTIK_ENDPOINT
		@strUserName = config.avantik.AVANTIK_USER_ACCOUNT
		@strPassword = config.avantik.AVANTIK_USER_PASSWORD
		@strAgencyCode = config.avantik.AVANTIK_AGENCY_CODE

###
	default value:
		only show CheckedIn passengers and Infants
###
class PassengerManifestReq
	constructor: () ->
		@PassengersManifestRequest =
			# @origin_rcd = ""
			# @destination_rcd = ""
			airline_rcd: ""
			flight_number: ""
			departure_date_from: ""
			# departure_date_to = ""
			# bReturnServices = ""
			# bReturnBagTags = ""
			# bReturnRemarks = ""
			bNotCheckedIn: false
			bCheckedIn: true
			bOffloaded: false
			bNoShow: false
			bInfants: true
			# bConfirmed = ""
			# bWaitlisted = ""
			# bCancelled = ""
			# bStandby = ""
			# bIndividual = ""
			# bGroup = ""
			# bTransit = ""
			# targetNSAlias = "tns"
			# targetNamespace = "http://tempuri.org/"

module.exports = {
	AvantikInitBean, PassengerManifestReq
}