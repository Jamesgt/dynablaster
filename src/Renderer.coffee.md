Renderer

	{PassEventEmitter} = require 'pee'
	{Table} = require './Table.coffee.md'

	class exports.Renderer extends PassEventEmitter

		tileSize: 50

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
				'X': new THREE.BoxGeometry @tileSize-2, @tileSize-2, @tileSize-2
				'S': new THREE.BoxGeometry @tileSize-2, @tileSize-2, @tileSize-2
				'F': new THREE.BoxGeometry @tileSize-2, @tileSize-2, @tileSize-2
				'1': new THREE.SphereGeometry @tileSize/2-2
				'2': new THREE.SphereGeometry @tileSize/2-2
				'B': new THREE.SphereGeometry @tileSize/2-4

			@scene = new THREE.Scene()
			@scene.add new THREE.AmbientLight new THREE.Color 0xffffff

			geometry = new THREE.PlaneBufferGeometry @w * @tileSize, @h * @tileSize, 1, 1
			@base = new THREE.Mesh geometry, @materials['_']
			@scene.add @base

			@scene.add @entities = new THREE.Object3D()

			@on 'render', => requestAnimationFrame => @render()
			@on 'remove', (e) => @entities.remove @entities.getObjectById e
			@on 'removeAll', =>
				while @entities.children.length > 0
					@entities.remove @entities.children[0]
			@on 'add', (e) => @addMesh e

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

		addMesh: (cell) ->
			return if cell.type is Table.EMPTY
			if cell.meshId?
				mesh = @entities.getObjectById cell.meshId
			else
				mesh = new THREE.Mesh @geometries[cell.type], @materials[cell.type]
				@entities.add mesh
				cell.meshId = mesh.id
			mesh.position.x = @tileSize * (-@w/2 + cell.x) + @tileSize/2
			mesh.position.y = @tileSize * (@h/2 - cell.y) - @tileSize/2

		render: ->
			@renderer.render @scene, @camera
