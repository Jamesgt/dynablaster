Build file.

	gulp = require 'gulp'
	jade = require 'gulp-jade'
	stylus = require 'gulp-stylus'
	coffee = require 'gulp-coffee'
	livereload = require 'gulp-livereload'
	concat = require 'gulp-concat'
	browserify = require 'gulp-browserify'
	rename = require 'gulp-rename'
	uglify = require 'gulp-uglify'

	gulp.task 'default', ['watch', 'all', 'devServer']
	gulp.task 'all', ['jade', 'stylus', 'coffee', 'copy']

	gulp.task 'watch', ->
		livereload.listen()
		gulp.watch './src/*.jade', ['jade']
		gulp.watch './src/*.styl', ['stylus']
		gulp.watch './src/*.coffee.md', ['coffee']

		gulp.watch(__filename).on 'change', ->
			delete require.cache[__filename]
			require __filename
			process.nextTick -> gulp.start ['all']

	gulp.task 'devServer', ->
		express = require 'express'
		logger = require 'morgan'

		@app = express()
		@app.use logger 'dev'
		@app.use express.static './dist'
		@app.listen 12345
		console.log "Web server listens on 12345."

	simpleTask = (extension, middleware) ->
		gulp.src './src/*.' + extension
		.pipe middleware
		.pipe gulp.dest './dist'
		.pipe livereload()

	gulp.task 'jade'  , -> simpleTask 'jade', jade()
	gulp.task 'stylus', -> simpleTask 'styl', stylus()

	gulp.task 'coffee', ->
		middleware = browserify transform: ['coffeeify'], extensions: ['.coffee.md']
		middleware.on 'error', (e) ->
			console.log '--- COFFEE SCRIPT ERROR ----------------'
			console.log e.name, ':', e.message
			console.log '----------------------------------------'
		gulp.src './src/entryPoint.coffee.md', read: no
		.pipe middleware
		.pipe rename 'game.js'
		# .pipe uglify()
		.pipe gulp.dest './dist'
		.pipe livereload()

	gulp.task 'copy', ->
		gulp.src [
			'./bower_components/jquery/dist/jquery.min.js'
			'./bower_components/threejs/build/three.min.js'
		]
		.pipe gulp.dest './dist/libs'

		gulp.src './res/**'
		.pipe gulp.dest './dist/res'
