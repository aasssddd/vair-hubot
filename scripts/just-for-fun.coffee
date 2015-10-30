# just-for-fun.coffee

module.exports = (robot) ->
	robot.on "off-the-work-notice", (res) ->
		robot.messageRoom process.env.AVANTIK_MESSAGE_ROOM ? "general", "Hey! let's call it a day!"

	robot.on "lunch-time", (res) ->
		robot.messageRoom process.env.AVANTIK_MESSAGE_ROOM ? "general", "Lunch time! wanna advise?\n ask me with \"help yelp\""