Build file.

	gulp = require 'gulp'
	jade = require 'gulp-jade'
	stylus = require 'gulp-stylus'
	nib = require 'nib'
	coffee = require 'gulp-coffee'
	livereload = require 'gulp-livereload'
	concat = require 'gulp-concat'
	browserify = require 'gulp-browserify'
	rename = require 'gulp-rename'
	uglify = require 'gulp-uglify'

	gulp.task 'default', ['watch', 'all', 'devServer']
	gulp.task 'all', ['jade', 'stylus', 'coffee']

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
		@app.use '/res', express.static './res'
		@app.listen 12345
		console.log "Web server listens on 12345."

	addErrorHandler = (name, middleware) ->
		middleware.on 'error', (e) ->
			console.log "--- #{name} ERROR ----------------------"
			console.log e.name, ':', e.message
			console.log '----------------------------------------'
		# return middleware

	gulp.task 'jade', ->
		gulp.src './src/*.jade'
		.pipe addErrorHandler 'Jade', jade locals: dev: yes
		.pipe gulp.dest './dist'
		.pipe livereload()

	gulp.task 'stylus', ->
		gulp.src './src/*.styl'
		.pipe addErrorHandler 'Stylus', stylus use: nib()
		.pipe gulp.dest './dist'
		.pipe livereload()

	gulp.task 'coffee', ->
		gulp.src './src/entryPoint.coffee.md', read: no
		.pipe addErrorHandler 'CoffeeScript', browserify transform: ['coffeeify'], extensions: ['.coffee.md']
		.pipe rename 'game.js'
		# .pipe uglify()
		.pipe gulp.dest './dist'
		.pipe livereload()
