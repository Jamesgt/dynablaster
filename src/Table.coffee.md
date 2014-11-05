Table

	PassEventEmitter = require './PassEventEmitter.coffee.md'

	module.exports = class Table extends PassEventEmitter

		@LAYER =
			BASE: 0
			DELAYED: 1

		@EXPLOSION_TIME: 3000
		@FIRE_TIME: 1000

		@EMPTY: '.'
		@WALL: 'X'
		@STONE: 'S'
		@BOMB: 'B'
		@FIRE: 'F'

		constructor: (@w, @h) ->
			@clear()

			@on 'tick', => @tick()

		clear: () ->
			@tables = [
				for [0...@h] then for [0...@w] then Table.EMPTY
				for [0...@h] then for [0...@w] then type: Table.EMPTY
			]

		standard: ->
			# walls
			@set 0, x, y, Table.WALL for y in [1...@h] by 2 for x in [1...@w] by 2
			# random stone blocks
			for y in [0...@h]
				for x in [0...@w] when @get(Table.LAYER.BASE, x, y) is Table.EMPTY
					@set 0, x, y, Table.STONE if Math.random() > 0.5

			@emit 'update'

		set: (layer, x, y, v) ->
			@tables[layer][y][x] = v

		get: (layer, x, y) ->
			@tables[layer][y][x]

		placeBomb: (x, y, firePower) ->
			cell = @get Table.LAYER.DELAYED, x, y
			delay = Table.EXPLOSION_TIME
			switch cell.type
				when Table.BOMB then return
				when Table.FIRE then delay = 0 # bomb on fire, immediate explosion

			@set Table.LAYER.DELAYED, x, y,
				type: Table.BOMB
				firePower: firePower
				at: Date.now() + delay - 1
			@emitLater 'tick', delay

		tick: () ->
			now = Date.now()
			finished = []
			for y in [0...@h]
				for x in [0...@w]
					cell = @get Table.LAYER.DELAYED, x, y
					if cell isnt Table.EMPTY and cell.at < now
						finished.push {x, y, cell}
			needsUpdate = no
			for item in finished
				switch item.cell.type
					when 'B'
						needsUpdate = true
						@explosion item.x, item.y, item.cell.firePower
						@emitLater 'tick', Table.FIRE_TIME
					when 'F'
						needsUpdate = true
						@set Table.LAYER.DELAYED, item.x, item.y, type: Table.EMPTY
			@emit 'update' if needsUpdate

		explosion: (x, y, firePower) ->
			@set Table.LAYER.DELAYED, x, y, type: Table.EMPTY
			@fire x, y
			for diff in [1..firePower] then break if @fire x-diff, y
			for diff in [1..firePower] then break if @fire x, y-diff
			for diff in [1..firePower] then break if @fire x+diff, y
			for diff in [1..firePower] then break if @fire x, y+diff

		# returns true if fire is stopped by obstacle or edge
		fire: (x, y) ->
			return yes if x < 0 or x >= @w or y < 0 or y >= @h # edge
			cell = @get Table.LAYER.BASE, x, y
			@emit 'death', cell unless isNaN parseInt cell # player
			switch cell
				when Table.WALL then return yes
				when Table.STONE then return @setOnFire x, y, yes
			cell = @get Table.LAYER.DELAYED, x, y
			@setOnFire x, y
			if cell.type is Table.BOMB # chain reaction
				@explosion x, y, cell.firePower

		setOnFire: (x, y, stop) ->
			@set Table.LAYER.BASE, x, y, Table.EMPTY
			@set Table.LAYER.DELAYED, x, y,
				type: Table.FIRE,
				at: Date.now() + Table.FIRE_TIME - 1
			return stop
