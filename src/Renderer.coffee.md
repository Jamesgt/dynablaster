Renderer

	{PassEventEmitter} = require 'pee'
	{Table} = require './Table.coffee.md'

	class exports.Renderer extends PassEventEmitter

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

			geometry = new THREE.PlaneBufferGeometry @table.w * @tileSize, @table.h * @tileSize, 1, 1
			@base = new THREE.Mesh geometry, @materials['_']
			@scene.add @base

			@scene.add @entities = new THREE.Object3D()

			@on 'update', => @update()
			@on 'render', => requestAnimationFrame => @render()
			@on 'remove', (e) => @entities.remove @entities.getObjectById e

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

		addMesh: (cell, x, y) ->
			return if cell.type is Table.EMPTY
			return if cell.meshId?
			material = @materials[cell.type]
			geometry = @geometries[cell.type]
			mesh = new THREE.Mesh geometry, material
			mesh.position.x = @tileSize * (-@table.w/2 + x) + @tileSize/2
			mesh.position.y = @tileSize * (@table.h/2 - y) - @tileSize/2
			@entities.add mesh
			cell.meshId = mesh.id

		update: ->
			for y in [0...@table.h]
				for x in [0...@table.w]
					cell = @table.get Table.LAYER.BASE, x, y
					@addMesh cell, x, y
					cell = @table.get Table.LAYER.DELAYED, x, y
					@addMesh cell, x, y
			@emit 'render'

		render: ->
			@renderer.render @scene, @camera
