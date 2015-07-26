{PassEventEmitter} = require 'pee'

{Table} = require './Table.coffee'
{Renderer} = require './Renderer.coffee'
{Player} = require './Player.coffee'
{Keyboard} = require './Keyboard.coffee'
{Settings} = require './Settings.coffee'

class exports.Game extends PassEventEmitter

	w: 15
	h: 15

	players: {}

	constructor: (@parentId) ->
		$('input[type="checkbox"]').bootstrapSwitch()
		Settings.init 'dynablaster',
			lights: yes
			playerAnimation: yes
			name: ''

		$('.modal').on 'hidden.bs.modal', (e) => setTimeout => @renderer.focus()

		$('#reset').click =>
			@reset()
			@renderer.focus()

		window.stats = new Stats()
		window.stats.setMode 1
		window.stats.domElement.style.position = 'absolute'
		window.stats.domElement.style.bottom = '0px'
		$("#stats").append window.stats.domElement

		@table = new Table @w, @h

		@renderer = new Renderer @parentId, @w, @h
		@table.pass 'render remove removeAll add setPosition addLight setLight', @renderer

		@keyboard = new Keyboard [['left', 'up', 'right', 'down'], ['action']],
			'1': Keyboard.SETS.ARROWS_ENTER
			'2': Keyboard.SETS.WASD_SPACE

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
		@table.standardPowerups()
		@renderer.emit 'render'
