# thai-app-playground.coffee

{GetCrewManifest} = require './lib/crew-manifest'

module.exports = (robot) ->

	robot.respond /test crew/i, (res) ->
		GetCrewManifest "ZV005", "2015/12/01", (err, data)->
			if err?
				res.reply "err...#{err}"
			else 
				res.reply "CrewData:\n #{JSON.stringify data, null, 4}"
