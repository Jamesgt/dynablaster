###
Keyboard class receives at init an array of grouped events and the corresponding id to keycodes map.
All events from the same group are emitted together and events from different groups are emitted separately.

Example:
`new Keyboard [['left', 'up', 'right', 'down'], ['action']],`
`    '1': [[37, 38, 39, 40], [13]] # left, up, right, down and enter`
`    '2': [[65, 87, 68, 83], [32]] # a, w, d, s and space`

Grouped keyboard events are emitted every `@INTERVAL` ms.
###
{PassEventEmitter} = require 'pee'

class exports.Keyboard extends PassEventEmitter

	INTERVAL: 40

	@KEYS:
		ARROW_LEFT: 37
		ARROW_UP: 38
		ARROW_RIGHT: 39
		ARROW_DOWN: 40
		ENTER: 13
		A: 65
		W: 87
		D: 68
		S: 83
		SPACE: 32

	@SETS:
		ARROWS: [Keyboard.KEYS.ARROW_LEFT, Keyboard.KEYS.ARROW_UP, Keyboard.KEYS.ARROW_RIGHT, Keyboard.KEYS.ARROW_DOWN]
		WASD: [Keyboard.KEYS.A, Keyboard.KEYS.W, Keyboard.KEYS.D, Keyboard.KEYS.S]
	Keyboard.SETS.ARROWS_ENTER = [Keyboard.SETS.ARROWS, [Keyboard.KEYS.ENTER]]
	Keyboard.SETS.WASD_SPACE = [Keyboard.SETS.WASD, [Keyboard.KEYS.SPACE]]

	###
	The `keys` map is an internal storage for easy lookup. `keyCode -> {groupIndex, id, event}`
	The `status` map is storing the actual key state.
	###
	constructor: (@events, @watchedKeys) ->
		@status = {}
		@keys = {}
		@keys[key] = {groupIndex, id, event: @events[groupIndex][i]} for key, i in keys for keys, groupIndex in keyGroups for id, keyGroups of @watchedKeys

		$('body')
			.keydown (e) => @key e.keyCode, yes
			.keyup (e) => @key e.keyCode, no

		@on 'tick', => @tick()

		@emitEvery 'tick', @INTERVAL

	###
	Example entry of toSend map: `'1' -> [['left', 'up'], ['action']]`.
	Emits `'1', 'left-up'` and `'1', 'action'`.
	###
	tick: () ->
		window.stats.begin()
		toSend = {}
		for own key, pressed of @status when pressed
			entry = @keys[key]
			toSend[entry.id] ?= []
			toSend[entry.id][entry.groupIndex] ?= []
			toSend[entry.id][entry.groupIndex].push entry.event
		@emit id, group.join '-' for group in groups when group for id, groups of toSend
		window.stats.end()

	key: (key, down) ->
		return unless @keys[key]? # skip if key is not watched

		@status[key] = down
