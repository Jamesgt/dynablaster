Table

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
				type: Table.EMPTY for [0...@h] for [0...@w]
				type: Table.EMPTY for [0...@h] for [0...@w]
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

**TODO**: remove debug comments and extra param of @emitMove.

		move: (x=0, y=0, v) ->
			# --- debug ---
			# console.log '------------------------------------------------------------------------------------'
			# console.log 'table.move', {x, y}, {x: v.x, y: v.y}, {x: v.subX, y: v.subY}, 'start'
			# --- debug ---
			# 1. toward center
			towardCenter = Math.abs(v.subX + x) <= Math.abs(v.subX) and Math.abs(v.subY + y) <= Math.abs(v.subY)
			return @emitMove v, x, y, 'tC' if towardCenter
			# 2. simplify double move
			if x isnt 0 and y isnt 0
				orig = {x, y}
				xempty = @canPlayerMoveTo v.x + x, v.y
				yempty = @canPlayerMoveTo v.x, v.y + y
				xredirectEmpty = @canPlayerMoveTo v.x + Math.sign(v.subX + x), v.y
				yredirectEmpty = @canPlayerMoveTo v.x, v.y + Math.sign(v.subY + y)
				# --- debug ---
				# console.log 'table.move', 'xe', xempty, 'xRe', xredirectEmpty, 'ye', yempty, 'yRe', yredirectEmpty
				# --- debug ---
				if xempty or xredirectEmpty
					y = 0
				else if yempty or yredirectEmpty
					x = 0
				# --- debug ---
				# console.log 'table.move', 'simplify', {x, y}
				# --- debug ---
				return if x isnt 0 and y isnt 0 # FIXME: ???????????????????????
			# 3. toward center again
			towardCenter = Math.abs(v.subX + x) <= Math.abs(v.subX) and Math.abs(v.subY + y) <= Math.abs(v.subY)
			return @emitMove v, x, y, 'tC2' if towardCenter
			# 4. skip if it is a dead-end
			empty = @canPlayerMoveTo v.x + x, v.y + y
			redirectEmpty = @canPlayerMoveTo v.x + Math.sign(v.subX + x), v.y + Math.sign(v.subY + y)
			return unless empty or redirectEmpty # nowhere to go
			# --- debug ---
			# console.log 'table.move',
			# 	'T', JSON.stringify({x: v.x + x, y: v.y + y}), 'E', empty
			# 	'T R', JSON.stringify({x: v.x + Math.sign(v.subX + x), y: v.y + Math.sign(v.subY + y)}), redirectEmpty
			# 	'S', JSON.stringify({x: v.subX, y: v.subY})
			# old = {x, y}
			# --- debug ---
			# 5. redirect near to corner
			{x, y} = switch
				when not empty then switch
					when x is 0 then {x: Math.sign(v.subX), y: 0}
					when y is 0 then {x: 0, y: Math.sign(v.subY)}
				else switch
					when x is 0 and v.subX isnt 0 and empty then {x: -Math.sign(v.subX), y: 0}
					when y is 0 and v.subY isnt 0 and empty then {x: 0, y: -Math.sign(v.subY)}
					else {x, y}
			# --- debug ---
			# console.log 'table.move', 'redirect', old, '->', {x, y} if old.x isnt x or old.y isnt y
			# --- debug ---
			# 6. same cell
			limit = Constants.SUB_LIMIT
			sameCell = -limit < v.subX + x <= limit and -limit < v.subY + y <= limit
			return @emitMove v, x, y, 'sC' if sameCell
			# 7. cell changed
			v.x += x
			v.y += y
			v.subX = @flipSub v.subX + x
			v.subY = @flipSub v.subY + y
			@emitMove v

		emitMove: (v, x, y, debug) ->
			if x? and y?
				v.subX += x
				v.subY += y
			# --- debug ---
			# console.log 'table.move', {x, y}, {x: v.x, y: v.y}, {x: v.subX, y: v.subY}, 'end', debug
			# --- debug ---
			@emit 'setPosition', v
			@emit 'render'

		flipSub: (n) ->
			switch n
		    	when -Constants.SUB_LIMIT     then  Constants.SUB_LIMIT
		    	when  Constants.SUB_LIMIT + 1 then -Constants.SUB_LIMIT + 1
		    	else n

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
