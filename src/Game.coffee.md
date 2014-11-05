Game base class

	Table = require './Table.coffee.md'
	Renderer = require './Renderer.coffee.md'
	Player = require './Player.coffee.md'
	Keyboard = require './Keyboard.coffee.md'
	PassEventEmitter = require './PassEventEmitter.coffee.md'

	module.exports = class Game extends PassEventEmitter

		w: 13
		h: 13

		players: {}

		constructor: (@parentId) ->
			$('#reset').click =>
				@reset()
				@renderer.focus()

			@table = new Table @w, @h

			@renderer = new Renderer @parentId, @table
			@table.pass 'update', @renderer

			@keyboard = new Keyboard ['left', 'up', 'right', 'down', 'action'],
				'1': [37, 38, 39, 40, 13] # left, up, right, down, enter
				'2': [65, 87, 68, 83, 32] # a, w, d, s, space

			@table.standard()

			@players =
				'1': new Player '1', @table, @w-1, @h-1
				'2': new Player '2', @table, 0, 0

			@keyboard.pass @players
			@table.on 'death', (id) =>
				console.log 'death', id

			@renderer.emit 'render'

		reset: () ->
			@table.clear()
			@table.standard()
			@players['1'].place @w-1, @h-1
			@players['2'].place 0, 0
