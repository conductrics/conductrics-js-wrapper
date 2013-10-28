# Adapted from https://github.com/litejs/browser-cookie-lite
CookieLite = (name, value, opts) ->
	if arguments.length > 1
		str = name + "=" + escape(value) +
			(if opts.ttl? then "; expires=" + new Date(+new Date()+(1e3*opts.ttl)).toUTCString() else "") +
			(if opts.path? then "; path=" + opts.path else "") # +
			(if opts.domain? then "; domain=" + opts.domain else "") +
			(if opts.secure? then "; secure" else "")
		return document.cookie = str
	return unescape((("; "+document.cookie).split("; "+name+"=")[1]||"").split(";")[0])
