{PassEventEmitter} = require 'pee'
{Table} = require './Table.coffee'

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

		@on 'action', =>
			return unless @bombs < @maxBombs
			@emit 'bomb', {@x, @y, @firePower, @type}

		@on 'bombPlaced', => @bombs++
		@on 'explosion', => @bombs--

		@on 'cellChanged', (e) =>
			switch e.newCell.type
				when '+F' then @firePower++
				when '+B' then @maxBombs++
			switch e.newCellDelayed.type
				when 'F' then Player.getGlobal().emit 'death', @type

		@reset @x, @y

	reset: (@x, @y) ->
		@firePower = 1
		@maxBombs = 1
		@bombs = 0

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
