Keyboard

	{PassEventEmitter} = require 'pee'

	class exports.Keyboard extends PassEventEmitter

		INTERVAL: 250

		status: {}
		keys: {}

		constructor: (@events, @watchedKeys) ->
			@keys[key] = id: id, event: @events[i] for key, i in keys for id, keys of @watchedKeys

			$('body').keydown (e) => @key e.keyCode, yes
			$('body').keyup (e) => @key e.keyCode, no

		key: (key, down) ->
			return unless @keys[key]? # skip if key is not watched

			if down
				unless @status[key]?
					@trigger key
					@status[key] = setInterval (=> @trigger key), @INTERVAL
			else
				clearInterval @status[key]
				delete @status[key]

		trigger: (key) ->
			@emit @keys[key].id, @keys[key].event
