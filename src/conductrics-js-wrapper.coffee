# Conductrics wrapper
class window.ConductricsJS
	constructor: (@owner, @apikey, @opts = {}) ->
		@opts.server ?= '//api.conductrics.com'
		@opts.timeout ?= 5000
		@opts.cookies ?= {ttl:(60*60*24*30), path:'/'}
		@opts.scodestore ?= CookieLite # pluggable - expected to be a getter/setter function that implements fn('key') for reads and fn('key', val) for writes
		@opts.session ?= @opts.scodestore?('mpid')
		@opts.transport ?= MicroAjax # pluggable - expected to be a factory that implements constructor args (url, timeout, cb)

	decision: (agent, opts = {}, cb = null) =>
		url = [agent, 'decisions']
		fb = null # fallback
		if opts.choices? # if provided, serialize decision/choice codes and determine fallback
			for key,val of opts.choices when val?.join?
				url.push "#{key}:#{val.join ','}" # when done and joined, something like: "/decisions/size:small,big/color:red,blue,green"
				fb ?= {}; fb[key] = code:val[0] unless fb[key]
			delete opts.choices
		@send url, opts, (res) ->
			return unless cb?
			selection = res?.decisions ? fb
			cb selection, res?.session

	goal: (agent, opts, cb) =>
		url = [agent, 'goal']
		if opts.goal? # if provided, add goal code to the url
			url.push opts.goal
			delete opts.goal
		@send url, opts, (res) ->
			return unless cb?
			success = res?.session?
			cb success, res?.session

	send: (url, data = {}, cb) =>
		data.apikey = @apikey
		data.session = @opts.session if @opts.session?
		data._t = new Date().getTime()
		url = "#{@opts.server}/#{@owner}/#{url.join '/'}?#{qsformat data}"
		new @opts.transport url, @opts.timeout, (text) =>
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
