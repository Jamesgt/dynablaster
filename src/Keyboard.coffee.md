Keyboard

	{PassEventEmitter} = require 'pee'

	class exports.Keyboard extends PassEventEmitter

		INTERVAL: 40

		status: {}
		keys: {}

		constructor: (@events, @watchedKeys) ->
			@keys[key] = {group, id, event: @events[group][i]} for key, i in keys for keys, group in keyGroups for id, keyGroups of @watchedKeys

			$('body').keydown (e) => @key e.keyCode, yes
			$('body').keyup (e) => @key e.keyCode, no

			@on 'trigger', (e) => @trigger e
			@on 'tick', => @tick()

			@emitEvery 'tick', @INTERVAL

		tick: () ->
			window.stats.begin()
			toSend = {}
			for own key, pressed of @status when pressed
				entry = @keys[key]
				toSend[entry.id] ?= []
				toSend[entry.id][entry.group] ?= []
				toSend[entry.id][entry.group].push entry.event
			@emit key, group.join '-' for group in groups when group for key, groups of toSend
			window.stats.end()

		key: (key, down) ->
			return unless @keys[key]? # skip if key is not watched

			@status[key] = down
