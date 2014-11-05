Table

	PassEventEmitter = require './PassEventEmitter.coffee.md'

	module.exports = class Table extends PassEventEmitter

		@LAYER =
			BASE: 0
			BOMBS: 1
			EXPLOSIONS: 2

		@EXPLOSION_TIME: 3000

		@EMPTY: '.'
		@WALL: 'X'
		@STONE: 'S'
		@BOMB: 'B'

		constructor: (@w, @h) ->
			@clear()

		clear: () ->
			@tables = for [0...3] then for [0...@h] then for [0...@w] then Table.EMPTY

		standard: ->
			# walls
			@set 0, x, y, Table.WALL for y in [1...@h] by 2 for x in [1...@w] by 2
			# stone blocks
			for y in [0...@h]
				for x in [0...@w] when @get(Table.LAYER.BASE, x, y) is Table.EMPTY
					@set 0, x, y, Table.STONE if Math.random() > 0.5

			@emit 'update'

		set: (layer, x, y, v) ->
			@tables[layer][y][x] = v

		get: (layer, x, y) ->
			@tables[layer][y][x]

		placeBomb: (x, y, firePower) ->
			return if @get(Table.LAYER.BOMBS, x, y) is Table.BOMB # there is already a bomb here
			@set Table.LAYER.BOMBS, x, y, Table.BOMB
			do (x, y, firePower) =>
				id = setTimeout (=> @explosion x, y), Table.EXPLOSION_TIME
				@set Table.LAYER.EXPLOSIONS, x, y, { id, firePower }

		explosion: (x, y, chain=no) ->
			# return if chain reaction already cleared this cell
			return if @get(Table.LAYER.BOMBS, x, y) is Table.EMPTY
			explosion = @get Table.LAYER.EXPLOSIONS, x, y
			clearTimeout explosion.id if chain # countdown is not needed any more
			@set Table.LAYER.EXPLOSIONS, x, y, Table.EMPTY

			# kaboom
			@set Table.LAYER.BOMBS, x, y, Table.EMPTY
			@fire x, y
			for diff in [1..explosion.firePower] then break if @fire x-diff, y
			for diff in [1..explosion.firePower] then break if @fire x, y-diff
			for diff in [1..explosion.firePower] then break if @fire x+diff, y
			for diff in [1..explosion.firePower] then break if @fire x, y+diff

			@emit 'update' unless chain # update only after the first explosion

		# returns true if fire is stopped by obstacle or edge
		fire: (x, y) =>
			return yes if x < 0 or x >= @w or y < 0 or y >= @h # edge
			@explosion x, y, yes if @get(1, x, y) is Table.BOMB # chain reaction
			cell = @get Table.LAYER.BASE, x, y
			@emit 'death', cell unless isNaN parseInt cell # player
			switch cell
				when Table.WALL then yes
				when Table.STONE
					@set Table.LAYER.BASE, x, y, Table.EMPTY
					yes
				else no
