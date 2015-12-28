# user.coffee

soap = require 'soap'
config = require 'app-config'
{parseString} = require 'xml2js'
{log} = require '../lib/vair-logger'
tosource = require 'tosource'

###
	query user data
	criteria:
		emp_no: "" 員編
		emp_name: "" 姓名
		emp_email: "" Email
###
module.exports.GetUserData = (criteria, callback)->
	function_id = "EmpData_A"
	options = 
		emp_no: ""
		emp_name: ""
		emp_email: ""

	if criteria?
		options = criteria

	param = 
		companyID: config.hrm.COMPANY_ID
		funcID: function_id
		filter: "MinDate=20150101;MaxDate=20151217"

	soap.createClient config.hrm.SERVICE_URL, (err, client) ->
		if err?
			log.error "#{err}"
			return callback err
		
		client.BOExpData param, (callErr, data) ->
			log.info "Request Header: #{JSON.stringify client.lastRequestHeaders}"
			log.info "Request Body: #{client.lastRequest}"
			log.info "Response Body #{client.lastResponse}"
			if callErr?
				log.error "#{callErr}"
				return callback callErr
			if data.BOExpDataResult?
				xmlString = data.BOExpDataResult
				parseString xmlString, (parseErr, parseResult) ->
					if parseErr?
						log.error "#{parseErr}"
						return callback parseErr
					resultSet = parseResult.Collection.RECD

					# filtering
					if not (options.emp_no is undefined or options.emp_no is "") and options.emp_no?
						log.info "filter with emp_no"
						resultSet = resultSet.filter (obj) ->
							match = obj.EMP_NO[0].toLowerCase().indexOf options.emp_no.toLowerCase()
							return match > -1
 
					if not (options.emp_name is undefined or options.emp_name is "") and options.emp_name?
						log.info "filter with emp_name"
						resultSet = resultSet.filter (obj) ->
							match = (obj.EMP_NM_C[0].toLowerCase().indexOf options.emp_name.toLowerCase()) + (obj.ALIAS_E[0].toLowerCase().indexOf options.emp_name.toLowerCase())
							return match > -2

					if not (options.emp_email is undefined or options.emp_email is "") and options.emp_email?
						log.info "filter with email"
						resultSet = resultSet.filter (obj) ->
							match = obj.E_MAIL_H[0].toLowerCase().indexOf options.emp_email.toLowerCase()
							return match > -1
					log.debug "filtered result: \n#{tosource resultSet}"
					callback null, resultSet
