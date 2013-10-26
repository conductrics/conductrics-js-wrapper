# conductrics-js-wrapper

**Experimental** lightweight wrapper for the key parts of the Conductrics API for bandit-style optimization, dynamic targeting, and A/B testing, with no dependencies on other libraries. We'll assume here that you are familiar with the basic idea of the service. If not, please see http://www.conductrics.com for information about the service itself.

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

You may provide an optional third argument to the constuctor, which is an options object that can contain:

+ `timeout` - timeout for all requests (decision, goal, etc) - the default is 5000 (five seconds)
+ `server` - default is **http://api.condutrics.com** - provide if you have been assigned a 'private' Conductrics server

```javascript
  var api = new ConductricsAPI('my-conductrics-owner-code', 'my-api-key', {timeout:1500});
```

### Notes and options for the decision() method

You may provide an optional second argument to the `decision` method, which is an options object that can contain:

+ `session` - a session ID to use to identify the visitor. In practice this is required at this time.
+ `point` - a point code, if you want to use the Conductrics "point" concept for decision attribution.
+ `choices` - an anonymous object that contains the options that Conductrics should select from. Each key is a decision to be made (typically one except in multivariate cases), and the value of each key should be an array of at least two choice codes.
  - For a simple decision, use something like `{version: ['a','b']}` - the selection from Conductrics will be something like `{version: {code:'b'}}`
  - For a multivariate-style decision, use something like `{size: ['small','large'], color: ['red','blue','green']}` - the selection from Conductrics will be something like `{size: {code:'large'}, color: {code:'blue'}}`

**Error handling / Fallback:** Assuming that you provide a `choices` object, then if the decision call fails (network error or timeout occurs, or an unsupported browser is being used, or if Conductrics returns an error because of a bad api key or something), the `selection` passed to your callback will be a fallback decision which looks like a "real" selection, but will be made up of the first choice for each decision. This generally results in gracefully degrading behavior with no extra coding on your part. If you don't provide a `choices` object, the `selection` passed to your callback will be `null` and you'll have to fall back gracefully on your own.

Note that all of the "codes" such as `point` and the keys and values in the `choices` object need to be "legal" codes - at this time, only ASCII letters, numbers, dashes, and underscores are allowed (the regex pattern for that would be `/[0-9A-Za-z_-]+/`).

### Notes and options for the goal() method

You may provide an optional second argument to the `goal` method, which is an options object that can contain:

+ `session` - a session ID to use to identify the visitor. In practice this is required at this time.
+ `reward` - an optional numeric value for the goal that was just achieved. If not provided, the server will use the agent's default (typically `1` unless otherwise specified).
+ `goal` - a goal code to identify which of your business goals has just been achieved. If not provided, the server will use the default goal code for the agent (typically `goal-1` unless otherwise specified).

License: MIT
