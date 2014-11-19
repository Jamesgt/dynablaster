Game base class

	{Table} = require './Table.coffee.md'
	{Renderer} = require './Renderer.coffee.md'
	{Player} = require './Player.coffee.md'
	{Keyboard} = require './Keyboard.coffee.md'
	{PassEventEmitter} = require 'pee'

	class exports.Game extends PassEventEmitter

		w: 13
		h: 13

		players: {}

		constructor: (@parentId) ->
			$('#reset').click =>
				@reset()
				@renderer.focus()

			@table = new Table @w, @h

			@renderer = new Renderer @parentId, @w, @h
			@table.pass 'render remove removeAll add setPosition', @renderer

			@keyboard = new Keyboard [['left', 'up', 'right', 'down'], ['action']],
				'1': [[37, 38, 39, 40], [13]] # left, up, right, down and enter
				'2': [[65, 87, 68, 83], [32]] # a, w, d, s and space

			@table.standard()

			PassEventEmitter.pass Player, 'clear set move update bomb', @table

			@players =
				'1': new Player '1', @w-1, @h-1
				'2': new Player '2', 0, 0

			@keyboard.pass @players

			@table.on 'death', (id) =>
				console.log 'death', id

			@renderer.emit 'render'

		reset: () ->
			@table.clearAll()
			@table.standard()
			@players['1'].reset @w-1, @h-1
			@players['2'].reset 0, 0
