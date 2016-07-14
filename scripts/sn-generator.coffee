# sn_generator.coffee

fs = require 'fs'
string = require 'string'
Logger = require('vair_log').Logger

log = Logger.getLogger()
###
	generate serial number
###
class SnGenerator
	@snFile: "./sn"

	###
		get new serial number
		options:
		{
			paddingLeft: {
				digits: 2 (default)
				char: '0' (default)
			},
			paddingRight: {
				digits: 0 (default)
				char: '' (default)
			}
			concatenate: {
				left: '' (default)
				right: ''(default)
			}
		}
	###
	@newNumber: (options, callback) ->
		opts = 
			paddingLeft:
				digits: 2
				char: '0'
			paddingRight:
				digits: 0
				char: ''
			concatenate:
				left: 'ZV'
				right: ''

		opts = options ? opts

		fs.access SnGenerator.snFile, (err) ->
			if err?
				log.info "not created! create new sn file"
				fs.writeFile SnGenerator.snFile, "1", (crtErr) ->
					if crtErr?
						log.error "create sn file error"
						return callback crtErr
				log.info "sn file created"
				sn = 1
				log.info "if block #{sn}"
			else 
				fs.readFile SnGenerator.snFile, "utf8", (rerr, data) ->
					if rerr?
						log.error "read err"
						return callback rerr
					else
						sn = parseInt data, 10
						sn++
						log.info " fs readFile block #{sn}"
						fs.writeFile SnGenerator.snFile, sn, 'utf8', (werr) ->
							if werr?
								log.error "write err"
								return callback werr

					log.info "else block = #{sn}"
					if sn > 0
						sn = string(sn).padLeft(opts.paddingLeft.digits, opts.paddingLeft.char).padRight(opts.paddingRight.digits, opts.paddingRight.char).s
						sn += opts.concatenate.right
						sn = opts.concatenate.left + sn

						log.info "final sn is #{sn}"
						return callback null, sn
					else 
						return callback 'unknow', null



module.exports.SnGenerator = SnGenerator