# avantik-bean.coffee
class AvantikBean
	constructor: () ->
		@url = process.env.AVANTIK_ENDOPINT
		@strUserName = process.env.AVANTIK_USER_ACCOUNT
		@strPassword = process.env.AVANTIK_USER_PASSWORD
		@strAgencyCode = process.env.AVANTIK_AGENCY_CODE
		@language = process.env.AVANTIK_LANGUAGE_CODE ? "ZH"

	verify: (@robot) ->
		if @url && @account && @password && @agency && @language
			@robot.send "OK"
		else
			@robot.send "avantik not configure well"

module.exports = {
	AvantikBean
}