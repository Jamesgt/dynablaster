Renderer

	PassEventEmitter = require './PassEventEmitter.coffee.md'

	module.exports = class Renderer extends PassEventEmitter

		tileSize: 50

		constructor: (@parentId, @table) ->
			@renderer = new THREE.WebGLRenderer antialias: yes
			@fillWindow()
			$("##{@parentId}").append @renderer.domElement
			@renderer.domElement.tabIndex = 1 # make canvas focusable
			$(window).bind 'resize', => @fillWindow()

			@materials =
				'_': @getMaterial 0xffffff, 'res/tile_tile_0022_01_thumb_256.jpg', yes
				'X': @getMaterial 0x999999, 'res/brick_stone_wall_0113_01_preview.jpg'
				'S': @getMaterial 0xffffff, 'res/brick_stone_wall_0113_01_preview.jpg'
				'1': @getMaterial 0xff9999, 'res/disturb.jpg'
				'2': @getMaterial 0x99ff99, 'res/disturb.jpg'
				'B': @getMaterial 0xffffff, 'res/lavatile.jpg'

			@scene = new THREE.Scene()
			@scene.add new THREE.AmbientLight new THREE.Color 0xffffff

			@container = new THREE.Object3D()
			@scene.add @container

			geometry = new THREE.PlaneBufferGeometry @table.w * @tileSize, @table.h * @tileSize, 1, 1
			@base = new THREE.Mesh geometry, @materials['_']
			@container.add @base

			@walls = new THREE.Object3D()
			@scene.add @walls

			@players = new THREE.Object3D()
			@scene.add @players

			@bombs = new THREE.Object3D()
			@scene.add @bombs

			@on 'update', => @update()
			@on 'render', => requestAnimationFrame => @render()

		focus: () ->
			@renderer.domElement.focus()

		fillWindow: ->
			w = window.innerWidth
			h = window.innerHeight
			@renderer.setSize w, h
			@camera = new THREE.PerspectiveCamera 50, w / h, 1, 5000
			@camera.position.z = 750
			@camera.rotation.x = 2*Math.PI
			@emit 'render'

		getMaterial: (color, url, repeat = no) ->
			material = new THREE.MeshLambertMaterial
				ambient: new THREE.Color color
				shading: THREE.FlatShading
			if url?
				texture = THREE.ImageUtils.loadTexture url, {}, =>
					material.needsUpdate = yes
					@emit 'render'
				if repeat
					texture.wrapS = texture.wrapT = THREE.RepeatWrapping
					texture.premultiplyAlpha = true
					texture.repeat.set 4, 4
				material.map = texture

			return material

		getEntity: (type, x, y) ->
			material = @materials[type]
			geometry = switch type
				when 'X' then new THREE.BoxGeometry @tileSize-2, @tileSize-2, @tileSize-2
				when 'S' then new THREE.BoxGeometry @tileSize-2, @tileSize-2, @tileSize-2
				when '1', '2' then new THREE.SphereGeometry @tileSize/2-2
				when 'B' then new THREE.SphereGeometry @tileSize/2-4

			entity = new THREE.Mesh geometry, material
			entity.position.x = @tileSize * (-@table.w/2 + x) + @tileSize/2
			entity.position.y = @tileSize * (@table.h/2 - y) - @tileSize/2
			return entity

		update: ->
			@walls.children = []
			@players.children = []
			@bombs.children = []
			for y in [0...@table.h]
				for x in [0...@table.w]
					for layer in [0...2]
						type = @table.get layer, x, y
						entity = @getEntity type, x, y
						switch type
							when 'X', 'S' then @walls.add entity
							when '1', '2' then @players.add entity
							when 'B' then @bombs.add entity
			@emit 'render'

		render: ->
			@renderer.render @scene, @camera
