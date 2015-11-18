# sn_generator.coffee

fs = require 'fs'
string = require 'string'

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
				console.log "not created! create new sn file"
				fs.writeFile SnGenerator.snFile, "1", (crtErr) ->
					if crtErr?
						console.log "create sn file error"
						return callback crtErr
				console.log "sn file created"
				sn = 1
				console.log "if block #{sn}"
			else 
				fs.readFile SnGenerator.snFile, "utf8", (rerr, data) ->
					if rerr?
						console.log "read err"
						return callback rerr
					else
						sn = parseInt data, 10
						sn++
						console.log " fs readFile block #{sn}"
						fs.writeFile SnGenerator.snFile, sn, 'utf8', (werr) ->
							if werr?
								console.log "write err"
								return callback werr

					console.log "else block = #{sn}"
					if sn > 0
						sn = string(sn).padLeft(opts.paddingLeft.digits, opts.paddingLeft.char).padRight(opts.paddingRight.digits, opts.paddingRight.char).s
						sn += opts.concatenate.right
						sn = opts.concatenate.left + sn

						console.log "final sn is #{sn}"
						return callback null, sn
					else 
						return callback 'unknow', null



module.exports.SnGenerator = SnGenerator