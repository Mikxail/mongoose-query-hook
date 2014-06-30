mongoose	= require 'mongoose'
Query		= mongoose.Query

wrap = (fn, wrap) ->
	->
		wrap.apply this, [fn].concat(Array::slice.call(arguments))


isPathced = false
pathMongoose = ->
	return if isPathced
	isPathced = true

	Query::withoutpre = (callback) ->
		@_withoutpre = true
		if typeof callback is 'function'
			@exec.call @, callback
		else
			@

	old = {}
	for act in ['update', 'remove', 'find', 'findOne', 'count', 'distinct', 'findOneAndRemove', 'findOneAndUpdate'] then do (act) ->
		Query::[act] = wrap Query::[act], (origFn, args...) ->
			if @_withoutpre or not @model?.schema?._usePreQuery or not @model?.schema?._preQuery or typeof args[args.length-1] isnt 'function'
				return origFn.apply @, args

			if @model?.schema?._usePreQuery and @model.schema._postQuery
				cb = args[args.length-1]
				self = @
				args[args.length-1] = (err, results) ->
					return cb.apply @, arguments if err?
					self.model.schema._postQuery.call @, self.op, results, cb

			@model.schema._preQuery.call @, @op
			# next
			, next = (err) =>
				if err?
					if typeof (cb = args[args.length-1]) is "function"
						return cb(err)
					else
						throw err
				origFn.apply @, args
			# done
			, done = (err = null, results = []) =>
				args[args.length-1].call @, err, results


module.exports = (schema, options = {}) ->
	pathMongoose()

	schema._usePreQuery = true

	if options.preQuery?
		schema._preQuery = options.preQuery

	if options.postQuery
		schema._postQuery = options.postQuery
