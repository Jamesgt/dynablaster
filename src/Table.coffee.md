Table

	arrayShuffle = require 'array-shuffle'
	{PassEventEmitter} = require 'pee'
	{Constants} = require './Constants.coffee.md'

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
		@BOMB: 'B'
		@FIRE: 'F'
		@POWERUP_PREFIX: '+'

		@POWERUP_COUNTS:
			'B': 7
			'F': 7

		constructor: (@w, @h) ->
			@clearAll()

			@on 'clear', (e) => @clear Table.LAYER.BASE, e.x, e.y, no
			@on 'set', (e) => @set Table.LAYER.BASE, e.x, e.y, e.v
			@on 'move', (e) => @move e.x, e.y, e.v
			@on 'bomb', (e) => @placeBomb e.x, e.y, e.firePower, e.type

			@on 'tick', => @tick()

		clearAll: () ->
			@tables = [
				type: Table.EMPTY for [0...@h] for [0...@w]
				type: Table.EMPTY for [0...@h] for [0...@w]
			]
			@emit 'removeAll'

		clear: (layer, x, y, wall=yes) ->
			@set layer, x, y, type: Table.EMPTY if wall or @get(layer, x, y).type isnt Table.WALL

		standard: () ->
			# walls and possible fire lights
			@set Table.LAYER.BASE, x, y, {type: Table.WALL, x, y} for y in [2...@h-1] by 2 for x in [2...@w-1] by 2
			for y in [0...@h]
				for x in [0...@w]
					if x is 0 or x is @w-1 or y is 0 or y is @h-1
						@set Table.LAYER.BASE, x, y, {type: Table.WALL, x, y}
					else
						@emit 'addLight', {x, y}
			# random stone blocks
			for y in [0...@h]
				for x in [0...@w] when @get(Table.LAYER.BASE, x, y).type is Table.EMPTY and Math.random() > 0.5
					@set Table.LAYER.BASE, x, y, {type: Table.STONE, x, y}

		standardPowerups: () ->
			stoneCells = []
			for y in [0...@h]
				for x in [0...@w]
					cell = @get Table.LAYER.BASE, x, y
					stoneCells.push cell if cell.type is Table.STONE
			stoneCells = arrayShuffle stoneCells
			for type, count of Table.POWERUP_COUNTS
				for [0...count]
					stoneCells.pop().powerup = {type: Table.POWERUP_PREFIX + type}

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

		canPlayerMoveTo: (x, y) ->
			return @get(Table.LAYER.BASE, x, y).type not in [Table.WALL, Table.STONE, Table.OUT]

This monster needs some doc. For smooth movement the vector is redirected if it is near to a corner, see point 5. below.

1. if moving toward the center of the current cell, then do it and nothing more to check
2. if double move (f.e: left and up), then simplify it to a simple move (current solution prefers horizontal moves on ambiguity)
3. vector changed, so check 1. again
4. skip this movement if it is a dead end (at least for this vector)
5. redirect vector near to corners
6. same cell, so only sub-values has to be changed
7. main cell changed, also flip the sub values

Sub cordinates represent the player position inside the cell.

		move: (x=0, y=0, v) ->
			# 1. toward center
			towardCenter = Math.abs(v.subX + x) <= Math.abs(v.subX) and Math.abs(v.subY + y) <= Math.abs(v.subY)
			return @emitMove v, x, y if towardCenter
			# 2. simplify double move
			if x isnt 0 and y isnt 0
				orig = {x, y}
				xempty = @canPlayerMoveTo v.x + x, v.y
				yempty = @canPlayerMoveTo v.x, v.y + y
				xredirectEmpty = @canPlayerMoveTo v.x + Math.sign(v.subX + x), v.y
				yredirectEmpty = @canPlayerMoveTo v.x, v.y + Math.sign(v.subY + y)
				if xempty or xredirectEmpty
					y = 0
				else if yempty or yredirectEmpty
					x = 0
				return if x isnt 0 and y isnt 0 # dead end
			# 3. toward center again
			towardCenter = Math.abs(v.subX + x) <= Math.abs(v.subX) and Math.abs(v.subY + y) <= Math.abs(v.subY)
			return @emitMove v, x, y if towardCenter
			# 4. skip if it is a dead-end
			empty = @canPlayerMoveTo v.x + x, v.y + y
			return unless empty or redirectEmpty # nowhere to go
			# 5. redirect near to corner
			{x, y} = switch
				when not empty then switch
					when x is 0 then {x: Math.sign(v.subX), y: 0}
					when y is 0 then {x: 0, y: Math.sign(v.subY)}
				else switch
					when x is 0 and v.subX isnt 0 and empty then {x: -Math.sign(v.subX), y: 0}
					when y is 0 and v.subY isnt 0 and empty then {x: 0, y: -Math.sign(v.subY)}
					else {x, y}
			redirectEmpty = @canPlayerMoveTo v.x + Math.sign(v.subX + x), v.y + Math.sign(v.subY + y)
			# 6. same cell
			limit = Constants.SUB_LIMIT
			sameCell = -limit < v.subX + x <= limit and -limit < v.subY + y <= limit
			return @emitMove v, x, y if sameCell
			# 7. cell changed
			@clear Table.LAYER.BASE, v.x, v.y
			v.x += x
			v.y += y
			v.subX = @flipSub v.subX + x
			v.subY = @flipSub v.subY + y
			newCell = @get(Table.LAYER.BASE, v.x, v.y)
			newCellDelayed = @get(Table.LAYER.DELAYED, v.x, v.y)
			v.emit 'cellChanged', {newCell, newCellDelayed}
			@emit 'setLight', {x: v.x, y: v.y, v: 0, type: newCell.type} if newCell.type[0] is Table.POWERUP_PREFIX
			@set Table.LAYER.BASE, v.x, v.y, v
			@emitMove v

		emitMove: (v, x, y) ->
			if x? and y?
				v.subX += x
				v.subY += y
			@emit 'setPosition', v
			@emit 'render'

		flipSub: (n) ->
			switch n
		    	when -Constants.SUB_LIMIT     then  Constants.SUB_LIMIT
		    	when  Constants.SUB_LIMIT + 1 then -Constants.SUB_LIMIT + 1
		    	else n

		placeBomb: (x, y, firePower, owner) ->
			delay = Table.EXPLOSION_TIME
			switch @get(Table.LAYER.DELAYED, x, y).type
				when Table.BOMB then return
				when Table.FIRE then delay = 0 # bomb on fire, immediate explosion

			@emit owner, 'bombPlaced'

			@set Table.LAYER.DELAYED, x, y,
				type: Table.BOMB
				x: x
				y: y
				firePower: firePower
				at: Date.now() + delay - 1
				owner: owner
			@emit 'render'
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
						@explosion item.cell
						@emitLater 'tick', Table.FIRE_TIME
					when 'F'
						needsUpdate = true
						@clear Table.LAYER.DELAYED, item.x, item.y
						if item.cell.powerup?
							item.cell.powerup.x = item.x
							item.cell.powerup.y = item.y
							@set Table.LAYER.BASE, item.x, item.y, item.cell.powerup
							@emit 'setLight', {x: item.x, y: item.y, v: 1, type: item.cell.powerup.type}
						else
							@emit 'setLight', {x: item.x, y: item.y, v: 0, type: Table.FIRE}
			@emit 'render' if needsUpdate

		explosion: (cell) ->
			@emit cell.owner, 'explosion'
			@clear Table.LAYER.DELAYED, cell.x, cell.y # remove the bomb
			@fire cell.x, cell.y
			for diff in [1..cell.firePower] then break if @fire cell.x-diff, cell.y
			for diff in [1..cell.firePower] then break if @fire cell.x,      cell.y-diff
			for diff in [1..cell.firePower] then break if @fire cell.x+diff, cell.y
			for diff in [1..cell.firePower] then break if @fire cell.x,      cell.y+diff

		# returns true if fire is stopped by obstacle or edge
		fire: (x, y) ->
			cell = @get Table.LAYER.BASE, x, y
			return yes if cell.type is Table.OUT # edge
			unless isNaN parseInt cell.type # player
				cell.emit 'cellChanged', 
					newCell: type: Table.EMPTY
					newCellDelayed: type: Table.FIRE
			switch cell.type
				when Table.WALL then return yes
				when Table.STONE then return @setOnFire x, y, yes
			cell = @get Table.LAYER.DELAYED, x, y
			@setOnFire x, y
			if cell.type is Table.BOMB # chain reaction
				@explosion cell

		setOnFire: (x, y, stop) ->
			{powerup} = @get(Table.LAYER.BASE, x, y)
			@clear Table.LAYER.BASE, x, y
			@emit 'setLight', {x, y, v: 1, type: Table.FIRE}
			@set Table.LAYER.DELAYED, x, y,
				type: Table.FIRE
				x: x
				y: y
				powerup: powerup
				at: Date.now() + Table.FIRE_TIME - 1
			return stop
