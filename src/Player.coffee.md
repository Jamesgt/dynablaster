Player

	{PassEventEmitter} = require 'pee'
	{Table} = require './Table.coffee.md'

	class exports.Player extends PassEventEmitter

		constructor: (@type, @x, @y) ->
			super()
			@keep = yes
			@firePower = 2

			@on @type, (e) => @emit e

			@on 'left', => @emit 'move', v: @, x: -1
			@on 'right', => @emit 'move', v: @, x: 1
			@on 'up', =>  @emit 'move', v: @, y: -1
			@on 'down', =>  @emit 'move', v: @, y: 1
			@on 'action', => @emit 'bomb', {@x, @y, @firePower}
			@on 'moved', (e) =>
				@x += e.x
				@y += e.y

			@place @x, @y

		place: (@x, @y) ->
			# clearing neighborhood of player
			@emit 'clear', x: @x-1, y: @y
			@emit 'clear', x: @x,   y: @y+1
			@emit 'clear', x: @x+1, y: @y
			@emit 'clear', x: @x,   y: @y-1
			@emit 'set', {v: @, @x, @y}
			@emit 'update'
