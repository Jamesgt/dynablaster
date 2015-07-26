class exports.Settings

    @_TYPES:
        CHECKBOXES: 'input[type="checkbox"][data-persist]'
        INPUTS: 'input[type="text"][data-persist]'
        BUTTONS: 'button[data-persist-target]'

    @namespace: ''
    @defaults: {}
    @instance: null

    @init: (namespace, defaults) ->
        Settings.namespace = namespace
        Settings.defaults = defaults
        Settings.get()
        Settings.save()

        $('.modal').on 'shown.bs.modal', (e) =>
            $(Settings._TYPES.CHECKBOXES).each (i, e) =>
                unless Settings.get(e.dataset.persist)
                    $(e).bootstrapSwitch('state', '')
        $(Settings._TYPES.CHECKBOXES).on 'switchChange.bootstrapSwitch', (e, state) =>
            Settings.set(e.target.dataset.persist, state)

        $(Settings._TYPES.INPUTS).each (i, e) =>
            $(e).val Settings.get(e.dataset.persist) ? ''
        $(Settings._TYPES.BUTTONS).click (e) =>
            $(e.target.dataset.persistTarget).each (i, e) =>
                Settings.set(e.dataset.persist, $(e).val())

    constructor: () ->
        Settings.settings = if localStorage[Settings.namespace] isnt undefined then JSON.parse localStorage[Settings.namespace] else {}
        Settings.set(k, v) for own k, v of Settings.defaults when not Settings.settings[k]?

    @get: (key) ->
        Settings.instance ?= new Settings()
        return unless key?
        return Settings.settings[key]

    @set: (key, value) ->
        Settings.settings[key] = value
        Settings.save()
        return value

    @save: () ->
        localStorage[Settings.namespace] = JSON.stringify Settings.settings
