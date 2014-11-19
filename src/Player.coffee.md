Player

	{PassEventEmitter} = require 'pee'
	{Table} = require './Table.coffee.md'

	class exports.Player extends PassEventEmitter

		@ANIMATION_TIME: 500

		constructor: (@type, @x, @y) ->
			super()
			@keep = yes

			@on @type, (e) => @emit e

			addDelegate = (events, {x, y}) =>
				@on event, (=> @emit 'move', v: @, x: x, y: y) for event in events.split ' '
			LEFT = UP = -1
			RIGHT = DOWN = 1
			addDelegate 'left',                  x: LEFT
			addDelegate 'right',                 x: RIGHT
			addDelegate 'up',                              y: UP
			addDelegate 'down',                            y: DOWN
			addDelegate 'left-up up-left',       x: LEFT,  y: UP
			addDelegate 'up-right right-up',     x: RIGHT, y: UP
			addDelegate 'right-down down-right', x: RIGHT, y: DOWN
			addDelegate 'left-down down-left',   x: LEFT,  y: DOWN
			@on 'action', => @emit 'bomb', {@x, @y, @firePower}

			@reset @x, @y

		reset: (@x, @y) ->
			@firePower = 2
			@subX = 0
			@subY = 0
			delete @meshId
			delete @lastDoubleMove

			@place @x, @y

		place: (@x, @y) ->
			# clearing neighborhood of player
			@emit 'clear', x: @x-1, y: @y
			@emit 'clear', x: @x,   y: @y+1
			@emit 'clear', x: @x+1, y: @y
			@emit 'clear', x: @x,   y: @y-1
			@emit 'set', {v: @, @x, @y}
			@emit 'update'
