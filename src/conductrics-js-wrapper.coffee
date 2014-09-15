# Conductrics wrapper
class window.ConductricsJS
	constructor: (@owner, @apikey, @opts = {}) ->
		@opts.server ?= '//api.conductrics.com'
		@opts.timeout ?= 5000
		@opts.cookies ?= {ttl:(60*60*24*30), path:'/'}
		@opts.scodestore ?= CookieLite # pluggable - expected to be a getter/setter function that implements fn('key') for reads and fn('key', val) for writes
		@opts.session ?= @opts.scodestore?('mpid')
		@opts.transport ?= MicroAjax # pluggable - expected to be a factory that implements constructor args (url, timeout, cb)
		@opts.batching ?= 'off'
		@batchStart() if @opts.batching in ['auto','manual']

	decision: (agent, opts = {}, cb = null) =>
		url = [agent, 'decisions']
		fb = null # fallback
		if opts.choices? # if provided, serialize decision/choice codes and determine fallback
			for key,val of opts.choices when val?.join?
				url.push "#{key}:#{val.join ','}" # when done and joined, something like: "/decisions/size:small,big/color:red,blue,green"
				fb ?= {}; fb[key] = code:val[0] unless fb[key]
			delete opts.choices
		if opts.fallback? # allow explicit fallback to be provided
			fb = opts.fallback
			delete opts.fallback
		@send url, opts, null, true, (res) ->
			return unless cb?
			selection = res?.decisions ? fb
			cb selection, res?.session

	goal: (agent, opts, cb) =>
		url = [agent, 'goal']
		if opts.goal? # if provided, add goal code to the url
			url.push opts.goal
			delete opts.goal
		@send url, opts, null, true, (res) ->
			return unless cb?
			success = res?.session?
			cb success, res?.session

	send: (url, data, body, batchable, cb) =>
		data.apikey = @apikey
		data.session = @opts.session if @opts.session?
		data._t = new Date().getTime()
		# if batching
		if batchable and @opts.batching in ['auto','manual']
			batchItem =
				agent: url[0]
				type: url[1]
				query: data
				cb: cb
			switch batchItem.type
				when 'decisions'
					batchItem.choices = url[2..].join('/') if url.length > 2
				when 'goal'
					batchItem.goal = url[2] if url.length > 2
			@batch.push batchItem # the callback will be called later, after we send the batch
			_batchSend(@) if @opts.batching is 'auto' # if it's manual, the user is supposed to call batchSend() themselves
			return
		# not batching
		url = "#{@opts.server}/#{@owner}/#{url.join '/'}?#{qsformat data}"
		new @opts.transport url, body, @opts.timeout, (text) =>
			try
				res = JSON.parse text
				cb res
			catch e
				cb null
			if res?.session? and @opts.cookies?
				@opts.session = res.session
				@opts.scodestore?('mpid', res.session, @opts.cookies)

	# helpers
	qsformat = (data) -> qs = ''; qs += "&#{k}=#{escape v}" for k,v of data; return qs
	debounce = (ms, f) ->
		timeout = null
		(a...) ->
			clearTimeout timeout
			setTimeout (=>
				f.apply @, a
			), ms

	# batch management
	_batchSend = debounce 20, (self) -> self.batchSend()
	batchStart: -> @batch = []
	batchSend: ->
		url = ['-','batch']
		batchData = @batch.concat()
		return unless batchData.length > 0
		@batchStart()
		@send url, {}, batchData, false, (results) ->
			return unless results?.length > 0
			for i of batchData when results[i]? and batchData[i]?
				batchData[i].cb results[i].data # call each deferred callback with the corresponding data
