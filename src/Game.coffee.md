Game base class

	{Table} = require './Table.coffee.md'
	{Renderer} = require './Renderer.coffee.md'
	{Player} = require './Player.coffee.md'
	{Keyboard} = require './Keyboard.coffee.md'
	{PassEventEmitter} = require 'pee'

	class exports.Game extends PassEventEmitter

		w: 15
		h: 15

		players: {}

		constructor: (@parentId) ->
			$('#reset').click =>
				@reset()
				@renderer.focus()
			window.stats = new Stats()
			window.stats.setMode 1
			window.stats.domElement.style.position = 'absolute'
			window.stats.domElement.style.bottom = '0px'
			$("#controls").append window.stats.domElement

			@table = new Table @w, @h

			@renderer = new Renderer @parentId, @w, @h
			@table.pass 'render remove removeAll add setPosition addLight setLight', @renderer

			@keyboard = new Keyboard [['left', 'up', 'right', 'down'], ['action']],
				'1': [[37, 38, 39, 40], [13]] # left, up, right, down and enter
				'2': [[65, 87, 68, 83], [32]] # a, w, d, s and space

			@table.standard()

			PassEventEmitter.pass Player, 'clear set move update bomb', @table

			@players =
				'1': new Player '1', @w-2, @h-2
				'2': new Player '2', 1, 1

			@table.standardPowerups()

			@keyboard.pass @players
			@table.pass @players

			PassEventEmitter.getGlobal().on 'death', (id) =>
				console.log 'death', id

			@renderer.emit 'render'

		reset: () ->
			@table.clearAll()
			@table.standard()
			@players['1'].reset @w-2, @h-2
			@players['2'].reset 1, 1
			@renderer.emit 'render'
