# just-for-fun.coffee

module.exports = (robot) ->

	robot.on "off-the-work-notice", (res) ->
		robot.messageRoom "general", "Hey! let's call it a day!"

	robot.on "lunch-time", (res) ->
		robot.messageRoom "general", "Lunch time! wanna advise?\n ask me with \"help yelp\""