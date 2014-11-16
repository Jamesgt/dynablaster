Table

	{PassEventEmitter} = require 'pee'

	class exports.Table extends PassEventEmitter

		@LAYER =
			BASE: 0
			DELAYED: 1

		@EXPLOSION_TIME: 3000
		@FIRE_TIME: 1000

		@OUT: '*'
		@EMPTY: '.'
		@WALL: 'X'
		@STONE: 'S'
		@POWER_UP: 'P'
		@BOMB: 'B'
		@FIRE: 'F'

		constructor: (@w, @h) ->
			@clearAll()

			@on 'clear', (e) => @clear Table.LAYER.BASE, e.x, e.y
			@on 'set', (e) => @set Table.LAYER.BASE, e.x, e.y, e.v
			@on 'move', (e) => @move e.x, e.y, e.v
			@on 'bomb', (e) => @placeBomb e.x, e.y, e.firePower

			@on 'tick', => @tick()

		clearAll: () ->
			@tables = [
				for [0...@h] then for [0...@w] then type: Table.EMPTY
				for [0...@h] then for [0...@w] then type: Table.EMPTY
			]
			@emit 'removeAll'

		clear: (layer, x, y) ->
			@set layer, x, y, type: Table.EMPTY

		standard: ->
			# walls
			@set 0, x, y, {type: Table.WALL, x, y} for y in [1...@h] by 2 for x in [1...@w] by 2
			# random stone blocks
			for y in [0...@h]
				for x in [0...@w] when @get(Table.LAYER.BASE, x, y).type is Table.EMPTY
					@set 0, x, y, {type: Table.STONE, x, y} if Math.random() > 0.5

			@emit 'render'

		set: (layer, x, y, v) ->
			return unless 0 <= x < @w and 0 <= y < @h
			old = @get layer, x, y
			if old.meshId?
				@emit 'remove', old.meshId unless old.keep
			unless v.type is Table.EMPTY and v.meshId?
				@emit 'add', v
			@tables[layer][y][x] = v

		get: (layer, x, y) ->
			return type: Table.OUT unless 0 <= x < @w and 0 <= y < @h
			return @tables[layer][y][x]

		isEmpty: (x, y) ->
			return @get(Table.LAYER.BASE, x, y).type is Table.EMPTY

		move: (x=0, y=0, v) ->
			if @isEmpty v.x+x, v.y+y
				# intentionally not using @clear, TODO: introduce Player.keep?
				@set Table.LAYER.BASE, v.x, v.y, type: Table.EMPTY
				v.emit 'moved', {x, y}
				@set Table.LAYER.BASE, v.x, v.y, v
				@emit 'render'

		placeBomb: (x, y, firePower) ->
			cell = @get Table.LAYER.DELAYED, x, y
			delay = Table.EXPLOSION_TIME
			switch cell.type
				when Table.BOMB then return
				when Table.FIRE then delay = 0 # bomb on fire, immediate explosion

			@set Table.LAYER.DELAYED, x, y,
				x: x
				y: y
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
						@clear Table.LAYER.DELAYED, item.x, item.y
			@emit 'render' if needsUpdate

		explosion: (x, y, firePower) ->
			@clear Table.LAYER.DELAYED, x, y # remove the bomb
			@fire x, y
			for diff in [1..firePower] then break if @fire x-diff, y
			for diff in [1..firePower] then break if @fire x, y-diff
			for diff in [1..firePower] then break if @fire x+diff, y
			for diff in [1..firePower] then break if @fire x, y+diff

		# returns true if fire is stopped by obstacle or edge
		fire: (x, y) ->
			cell = @get Table.LAYER.BASE, x, y
			return yes if cell.type is Table.OUT # edge
			@emit 'death', cell.type unless isNaN parseInt cell.type # player
			switch cell.type
				when Table.WALL then return yes
				when Table.STONE then return @setOnFire x, y, yes
			cell = @get Table.LAYER.DELAYED, x, y
			@setOnFire x, y
			if cell.type is Table.BOMB # chain reaction
				@explosion x, y, cell.firePower

		setOnFire: (x, y, stop) ->
			@clear Table.LAYER.BASE, x, y
			@set Table.LAYER.DELAYED, x, y,
				x: x
				y: y
				type: Table.FIRE,
				at: Date.now() + Table.FIRE_TIME - 1
			return stop
