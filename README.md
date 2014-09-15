# conductrics-js-wrapper

Lightweight wrapper for the key parts of the Conductrics API for bandit-style optimization, dynamic targeting, and A/B testing, with no dependencies on other libraries. We'll assume here that you are familiar with the basic idea of the service. If not, please see http://www.conductrics.com for information about the service itself.

Please see https://github.com/conductrics/conductrics-jquery for a more fully-featured and field-tested wrapper.

## Quick Example Usage

Here's the basics. There's a more complete working example in the /examples folder.

```javascript
	// Initialize by passing your Conductrics account credentials to constructor
	var api = new ConductricsAPI('my-conductrics-owner-code', 'my-api-key');

	// Get a decision from an agent
	var choices = {'version':['a','b']}; // optional, see notes below
	var session = '12345'; // in practice you get this from a cookie or something
	api.decision 'my-agent', {session:session, choices:choices}, function(selection) {
		// selection looks like this, which you can use to do whatever: {'version': {code:'b'}}
	});

	// Later, send a reward to the agent
	api.goal 'my-agent', {session:session}, function(response) {
		// generally nothing to actually do afterward
	}
```

### Options for the Constructor

You may provide an optional third argument to the constuctor, which is an options object that may contain:

+ `timeout` - timeout for all requests (decision, goal, etc) - the default is 5000 (five seconds)
+ `session` - a session identifier to pass to Conductrics. If null or not provided, this wrapper will receive a session identifier from the server the first time decision() is called, which will be kept as a cookie for you by default.
+ `cookies` - an object which may contain any of the following to control how session are tracked between page views using cookies (or you can set `cookies` to `null` to disable the cookie tracking altogether):
  - `ttl` - the length of time that the cookie should be persisted for - default is 30 days. Use a ttl of 0 to specify that the cookie should persist only until the user closes their browser.
  - `domain` - can be used to specify a domain such as `.example.com` (note leading dot)
  - `path` - by default, `/` is used which is usually appropriate.
  - `secure` - set to true to indicate that the cookie should be shared amongst secure (SSL) pages only

```javascript
  var api = new ConductricsAPI('my-conductrics-owner-code', 'my-api-key', {timeout:1500});
```

A few more advanced options:

+ `server` - provide if you have been assigned a 'private' Conductrics server - the default is `//api.condutrics.com` (we recommend starting with `//`, which will cause http:// or https:// to be used dynamically at runtime)
+ `transport` - pluggable transport, see source for details. If you provide your own transport, you could re-compile the JavaScript without micro-ajax for a smaller file size.
+ `scodestore` - pluggable session code store, see source for details. If you provide your own store, you could re-compile the JavaScript without cookie-lite for a smaller file size.

### Notes and options for the decision() method

You may provide an optional second argument to the `decision` method, which is an options object that can contain:

+ `session` - a session ID to use to identify the visitor. If null or not provided, the server will create a session id, which this wrapper will retain as a session cookie by default (see `cookies` option for the constructor). Cookies are not set if you provide a `session` explicitly here.
+ `point` - a point code, if you want to use the Conductrics "point" concept for decision attribution.
+ `choices` - an anonymous object that contains the options that Conductrics should select from. Each key is a decision to be made (typically one except in multivariate cases), and the value of each key should be an array of at least two choice codes.
  - For a simple decision, use something like `{version: ['a','b']}` - the selection from Conductrics will be something like `{version: {code:'b'}}`
  - For a multivariate-style decision, use something like `{size: ['small','large'], color: ['red','blue','green']}` - the selection from Conductrics will be something like `{size: {code:'large'}, color: {code:'blue'}}`

**Error handling / Fallback:** Assuming that you provide a `choices` object, then if the decision call fails (network error or timeout occurs, or an unsupported browser is being used, or if Conductrics returns an error because of a bad api key or something), the `selection` passed to your callback will be a fallback decision which looks like a "real" selection, but will be made up of the first choice for each decision. This generally results in gracefully degrading behavior with no extra coding on your part. If you don't provide a `choices` object, the `selection` passed to your callback will be `null` and you'll have to fall back gracefully on your own.

Note that all of the "codes" such as `point` and the keys and values in the `choices` object need to be "legal" codes - at this time, only ASCII letters, numbers, dashes, and underscores are allowed (the regex pattern for that would be `/[0-9A-Za-z_-]+/`).

### Notes and options for the goal() method

You may provide an optional second argument to the `goal` method, which is an options object that can contain:

+ `session` - a session ID to use to identify the visitor (see notes above).
+ `reward` - an optional numeric value for the goal that was just achieved. If not provided, the server will use the agent's default (typically `1` unless otherwise specified).
+ `goal` - a goal code to identify which of your business goals has just been achieved. If not provided, the server will use the default goal code for the agent (typically `goal-1` unless otherwise specified).

### Request Batching (BETA) ###

Normally, each decision or reward call results in an HTTP request to Conductrics. If lots of decisions (or rewards) for different agents may be made on a web page, it is possible that this could result in a bunch of HTTP requests, which could have a negative impact on performance (depending on when your code makes the calls).

There are two batching options:

- **Automatic batching**. Just add `batching:'auto'` in the options object for the constructor.
- **Manual batching**. Add `batching:'manual'` for the options object for the constructor. Now call `batchStart()` before the decision() and goal() calls you would like batched, and then `batchSend()` to send them to Conductrics.

With either the automatic or manual mode, the callbacks for each of your decision/reward calls will be executed normally when the batched response is received from Conductrics. In other words, you shouldn't have to change the decision() and reward() calls themselves, or their callback handlers.

Acknowledgements: Includes adapted versions of https://github.com/litejs/browser-cookie-lite and https://code.google.com/p/microajax/

License: MIT
