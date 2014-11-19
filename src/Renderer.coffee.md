Renderer

	{PassEventEmitter} = require 'pee'
	{Table} = require './Table.coffee.md'
	{Constants} = require './Constants.coffee.md'

	class exports.Renderer extends PassEventEmitter

		constructor: (@parentId, @w, @h) ->
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
				'F': @getMaterial 0xffffff, 'res/fire-jpg_256.jpg'

			@geometries =
				'X': new THREE.BoxGeometry Constants.TILE_SIZE, Constants.TILE_SIZE, Constants.TILE_SIZE
				'S': new THREE.BoxGeometry Constants.TILE_SIZE, Constants.TILE_SIZE, Constants.TILE_SIZE
				'F': new THREE.BoxGeometry Constants.TILE_SIZE, Constants.TILE_SIZE, Constants.TILE_SIZE
				'1': new THREE.SphereGeometry Constants.TILE_SIZE / 2 - 2
				'2': new THREE.SphereGeometry Constants.TILE_SIZE / 2 - 2
				'B': new THREE.SphereGeometry Constants.TILE_SIZE / 2 - 4

			@scene = new THREE.Scene()
			@scene.add new THREE.AmbientLight new THREE.Color 0xffffff

			geometry = new THREE.PlaneBufferGeometry @w * Constants.TILE_SIZE, @h * Constants.TILE_SIZE, 1, 1
			@base = new THREE.Mesh geometry, @materials['_']
			@scene.add @base

			@scene.add @lights = new THREE.Object3D()
			@scene.add @entities = new THREE.Object3D()

			@on 'render', => requestAnimationFrame => @render()
			@on 'addLight', (e) =>
				@lights.add light = new THREE.PointLight 0xff4444, 0, 3 * Constants.TILE_SIZE
				p = @toRenderCoords e
				light.position.set p.x, p.y, p.z + 2 * Constants.TILE_SIZE
				light.name = e.y + ',' + e.x
			@on 'setLight', (e) =>
				light = @lights.getObjectByName e.y + ',' + e.x
				light.intensity = e.v
			@on 'remove', (e) => @entities.remove @entities.getObjectById e
			@on 'removeAll', =>
				while @entities.children.length > 0
					@entities.remove @entities.children[0]
			@on 'add', (e) => @addMesh e
			@on 'setPosition', (e) => @setMeshPosition e

		focus: () ->
			@renderer.domElement.focus()

		fillWindow: ->
			w = window.innerWidth
			h = window.innerHeight
			@renderer.setSize w, h
			@camera = new THREE.PerspectiveCamera 50, w / h, 1, 5000
			@camera.position.z = 875
			@camera.rotation.x = 2 * Math.PI
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

		addMesh: (cell) ->
			return if cell.type is Table.EMPTY # TODO: needed?
			unless cell.meshId?
				mesh = new THREE.Mesh @geometries[cell.type], @materials[cell.type]
				@entities.add mesh
				cell.meshId = mesh.id
			@setMeshPosition cell

		setMeshPosition: (cell) ->
			mesh = @entities.getObjectById cell.meshId
			p = @toRenderCoords cell
			mesh.position.set p.x, p.y, p.z
			unless isNaN parseInt cell.type # player
				mesh.rotation.y = -2 * Math.PI * (cell.subX + Constants.SUB_LIMIT - 1) / Constants.SUB_ROTATE_RATE
				mesh.rotation.x =  2 * Math.PI * (cell.subY + Constants.SUB_LIMIT - 1) / Constants.SUB_ROTATE_RATE

		toRenderCoords: (cell) ->
			x: Constants.TILE_SIZE * ( 0.5 + -@w / 2 + cell.x) + Constants.SUB_MOVE_RATE * (cell.subX ? 0)
			y: Constants.TILE_SIZE * (-0.5 +  @h / 2 - cell.y) - Constants.SUB_MOVE_RATE * (cell.subY ? 0)
			z: Constants.TILE_SIZE * 0.5

		render: ->
			@renderer.render @scene, @camera
