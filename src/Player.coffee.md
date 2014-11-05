Player

	PassEventEmitter = require './PassEventEmitter.coffee.md'
	Table = require './Table.coffee.md'

	module.exports = class Player extends PassEventEmitter

		constructor: (@id, @table, @x, @y) ->
			@firePower = 2

			@on @id, (e) =>
				@lastx = @x
				@lasty = @y
				@emit e

			@on 'left', => @left()
			@on 'right', => @right()
			@on 'up', => @up()
			@on 'down', => @down()
			@on 'action', => @action()

			@place @x, @y

		place: (@x, @y) ->
			@lastx = @x
			@lasty = @y
			# clearing neighborhood of player
			@table.set 0, @x-1, @y, Table.EMPTY if @x > 0
			@table.set 0, @x, @y+1, Table.EMPTY if @y < @table.h - 1
			@table.set 0, @x+1, @y, Table.EMPTY if @x < @table.w - 1
			@table.set 0, @x, @y-1, Table.EMPTY if @y > 0

			@moved()

		moved: () ->
			@table.set 0, @lastx, @lasty, Table.EMPTY
			@table.set 0, @x, @y, @id
			@table.emit 'update'

		left: () ->
			@x-- if @x > 0 and @table.get(0, @x-1, @y) is Table.EMPTY
			@moved()

		up: () ->
			@y-- if @y > 0 and @table.get(0, @x, @y-1) is Table.EMPTY
			@moved()

		right: () ->
			@x++ if @x < @table.w - 1 and @table.get(0, @x+1, @y) is Table.EMPTY
			@moved()

		down: () ->
			@y++ if @y < @table.h - 1 and @table.get(0, @x, @y+1) is Table.EMPTY
			@moved()

		action: () ->
			@table.placeBomb @x, @y, @firePower
