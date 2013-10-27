# Conductrics wrapper
class window.ConductricsJS
	constructor: (@owner, @apikey, @options = {}) ->
		@options.server ?= 'http://api.conductrics.com'
		@options.timeout ?= 5000
		@options.transport ?= MicroAjax # pluggable - expected to be a factory that implements constructor args (url, timeout, callback)

	decision: (agent, options = {}, callback = null) =>
		endpoint = [agent, 'decisions']
		fallback = null
		if options.choices? # if provided, serialize decision/choice codes and determine fallback
			for key,val of options.choices when val?.join?
				endpoint.push "#{key}:#{val.join ','}" # when done and joined, something like: "/decisions/size:small,big/color:red,blue,green"
				fallback ?= {}; fallback[key] = code:val[0] unless fallback[key]
			delete options.choices
		@send endpoint, options, (response) ->
			return unless callback?
			selection = response?.decisions ? fallback
			callback selection

	goal: (agent, options, callback) =>
		endpoint = [agent, 'goal']
		if options.goal? # if provided, add goal code to the url
			endpoint.push options.goal
			delete options.goal
		@send endpoint, options, callback

	send: (endpoint, data = {}, callback) =>
		data.apikey = @apikey
		data._t = new Date().getTime()
		url = "#{@options.server}/#{@owner}/#{endpoint.join '/'}?#{qsformat data}"
		new @options.transport url, @options.timeout, (res) =>
			try
				callback JSON.parse(res)
			catch e
				callback null

	# helpers
	qsformat = (data) -> qs = ''; qs += "&#{k}=#{escape v}" for k,v of data; return qs
