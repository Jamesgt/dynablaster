Player

	{PassEventEmitter} = require 'pee'
	{Table} = require './Table.coffee.md'

	class exports.Player extends PassEventEmitter

		@ANIMATION_TIME: 500

		constructor: (@type, @x, @y) ->
			super()
			@keep = yes

			@on @type, (e) => @emit e

			LEFT = UP = -1
			RIGHT = DOWN = 1
			@on 'left', => @emit 'move', v: @, x: LEFT
			@on 'right', => @emit 'move', v: @, x: RIGHT
			@on 'up', => @emit 'move', v: @, y: UP
			@on 'down', => @emit 'move', v: @, y: DOWN
			@on 'left-up', => @emit 'move', v: @, x: LEFT, y: UP
			@on 'up-right', => @emit 'move', v: @, x: RIGHT, y: UP
			@on 'right-down', => @emit 'move', v: @, x: RIGHT, y: DOWN
			@on 'left-down', => @emit 'move', v: @, x: LEFT, y: DOWN
			@on 'animate', => @animate()
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
