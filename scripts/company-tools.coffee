# company-tools.coffee
# Description:
#   Find contact
# Commands:
#	hubot find email xxx@vair.com.tw - find by email
#	hubot find xxx - find by name
#	hubot find no xxx - find by employee no.
#
# Notes:
#   portal for manipulate thai-app
#
{GetUserData} = require './hrlib/user'
tosource = require 'tosource'
Logger = require('vair_log').Logger

module.exports = (robot) ->
	log = Logger.getLogger()
	# robot.logger = Logger.getLogger()
	robot.respond /find email\s*(.*)?/i, (res) ->
		options = 
			emp_email: res.match[1]

		log.info "options: #{tosource options}"
		GetUserData options, (err, data)->
			if err?
				log.error "Errrr.... #{err}"
				res.reply "Errrrrr....#{err}"
			else
				res.reply "#{options.emp_email} 的資訊如下:"
				data.forEach (obj) ->
					res.reply "\n姓名: #{obj.EMP_NM_C[0]}\n英文姓名: #{obj.ALIAS_E[0]}\n員編: #{obj.EMP_NO[0]}\n分機: #{obj.TEL_OF[0]}\n手機: #{obj.VIP_ACT_TEL[0]}\nEMail: #{obj.E_MAIL_H[0]}"


	robot.respond /find\s*(.*)?/i, (res) ->
		options = 
			emp_name: res.match[1]

		log.info "options: #{tosource options}"
		GetUserData options, (err, data)->
			if err?
				log.error "Errrr.... #{err}"
				res.reply "Errrrrr....#{err}"
			else
				res.reply "#{options.emp_name} 的資訊如下:"
				data.forEach (obj) ->
					res.reply "\n姓名: #{obj.EMP_NM_C[0]}\n英文姓名: #{obj.ALIAS_E[0]}\n員編: #{obj.EMP_NO[0]}\n分機: #{obj.TEL_OF[0]}\n手機: #{obj.VIP_ACT_TEL[0]}\nEMail: #{obj.E_MAIL_H[0]}"

	robot.respond /find no\s*(.*)?/i, (res) ->
		options = 
			emp_no: res.match[1]

		log.info "options: #{tosource options}"
		GetUserData options, (err, data)->
			if err?
				log.error "Errrr.... #{err}"
				res.reply "Errrrrr....#{err}"
			else
				if data.length <= 0
					return res.reply "誰啊，不認識"
				res.reply "#{options.emp_no} 的資訊如下:"
				data.forEach (obj) ->
					res.reply "\n姓名: #{obj.EMP_NM_C[0]}\n英文姓名: #{obj.ALIAS_E[0]}\n員編: #{obj.EMP_NO[0]}\n分機: #{obj.TEL_OF[0]}\n手機: #{obj.VIP_ACT_TEL[0]}\nEMail: #{obj.E_MAIL_H[0]}\n"