# just-for-fun.coffee

module.exports = (robot) ->
	robot.on "scheduled-task", (res) ->
		robot.messageRoom process.env.AVANTIK_MESSAGE_ROOM ? "william_test_hubot", "yay~"

	robot.on "off-the-work-notice", (res) ->
		robot.messageRoom process.env.AVANTIK_MESSAGE_ROOM ? "general", "Hey! let's call it a day!"

