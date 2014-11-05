Just another dead simple event emitter.

	module.exports = class PassEventEmitter

		on: (name, callback) ->
			return unless callback?
			return if name is ''
			@_events ?= {}
			@_events[name] ?= []
			@_events[name].push callback
			return

		emit: (name, e) ->
			@_events ?= {}
			callback e for callback in @_events[name] if @_events[name]?
			return

		pass: (names, target) ->
			# if names is an object ([] or {} or ->) and target is null
			if names is Object(names) and not target?
				# only handles {}
				@pass name, t for own name, t of names
				return
			return unless target?
			for name in names.split ' '
				continue if name is ''
				unless Array.isArray target
					do (name, target) => @on name, (e) -> target.emit name, e
					continue
				target.forEach (t) =>
					return unless t?
					do (name, t) => @on name, (e) -> t.emit name, e
			return
