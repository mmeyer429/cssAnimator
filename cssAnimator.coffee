### 
Developed by Martin Meyer 2012
###

do ->
	### /////////////////////////////// pollify for requestanimation  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ ###
	w = window
	for vendor in ['ms', 'moz', 'webkit', 'o']
		break if w.requestAnimationFrame
		w.requestAnimationFrame = w["#{vendor}RequestAnimationFrame"]
		w.cancelAnimationFrame = (w["#{vendor}CancelAnimationFrame"] or w["#{vendor}CancelRequestAnimationFrame"])

	# deal with the case where rAF is built in but cAF is not.
	if w.requestAnimationFrame
		return if w.cancelAnimationFrame
		browserRaf = w.requestAnimationFrame
		canceled = {}
		w.requestAnimationFrame = (callback) ->
			id = browserRaf (time) ->
				if id of canceled then delete canceled[id]
				else callback time
		w.cancelAnimationFrame = (id) -> canceled[id] = true

	# handle legacy browsers which don’t implement rAF
	else
		targetTime = 0
		w.requestAnimationFrame = (callback) ->
			targetTime = Math.max targetTime + 16, currentTime = +new Date
			w.setTimeout (-> callback +new Date), targetTime - currentTime

		w.cancelAnimationFrame = (id) -> clearTimeout id

### /////////////////////////////// end of pollify for requestanimation  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ ###

class Animator
	constructor: ( @el, @from, @to, @delay = 500, @callback = ->) ->
		@cssPropertyTypesCache = [];
		@cssPropertyTypesCached = false
		return @

	animate: (time) -> 
		me = @
		if !time?
			console.error "animation Witout time"
			return

		now = new Date().getTime()

		timePos = (now - @startTime) / @delay

		if timePos > 1
			timePos = 1
		@draw  timePos
		
		if timePos is 1
			@callback()
			return

		window.requestAnimationFrame (time)-> me.animate.call(me,time)


	start: ->
		@startTime = new Date().getTime()
		@doCache()
		@animate @startTime
		return

	doCache: ->
		for cssProperty, value of @from
			@cssPropertyTypesCache[cssProperty] = []
			@cssPropertyTypesCache[cssProperty] = @analize @cssPropertyTypesCache[cssProperty], cssProperty, value
		@cssPropertyTypesCached = true

	draw: (timePos) ->
		if not @cssPropertyTypesCached
			@doCache()
		valuesToAdd = {}
		for cssProperty, value of @from
			to = @to[cssProperty]
			from = @from[cssProperty]
			cache = @cssPropertyTypesCache[cssProperty]
			newValue = []
			for innerValue, index in value
				if cache[index]
					newValue.push @getUpdatedRule(cache[index], innerValue, index, to, from, timePos)
				else 
					valueToAdd = ""
					for key, objValue of innerValue
						valueToAdd += key + "("
						for innerObjValue, objValueIndex in objValue
							if objValueIndex isnt 0
								valueToAdd += ', '
							valueToAdd += @getUpdatedRule(cache[key][objValueIndex], innerObjValue, objValueIndex, to[index][key], from[index][key], timePos)
						valueToAdd += ")"
						newValue.push valueToAdd
			if Animator.utils.needPrefixFix cssProperty
				for prefix in Animator.utils.PREFIX
					valuesToAdd[cssProperty.replace('-prefix-', prefix)] =  newValue.join(' ')
			else
				valuesToAdd[cssProperty] =  newValue.join(' ')
		@updateStyles valuesToAdd

	getUpdatedRule: (cache, innerValue, index, to, from, timePos) ->
		if cache is Animator.utils.NUMERIC
			type = Animator.utils.getTypeExt cache, innerValue
			return ((parseFloat(to[index]) - parseFloat(innerValue)) * timePos) + parseFloat(innerValue) + type
		else if cache is Animator.utils.COLOR
			fromColor = Animator.utils.convertHexColorToDec innerValue
			toColor =  Animator.utils.convertHexColorToDec to[index]
			newColor = 
				r: parseInt ((toColor.r - fromColor.r) * timePos) + fromColor.r
				g: parseInt ((toColor.g - fromColor.g) * timePos) + fromColor.g
				b: parseInt ((toColor.b - fromColor.b) * timePos) + fromColor.b
			return Animator.utils.convertDecColorToHex newColor
		else
			if timePos >= 0.5
				return to[index]
			else
				return innerValue

	analize: (Cache, cssProperty, value) ->
		if typeof value is "string"
			Cache.push(Animator.utils.getType value)
		else if value.length isnt undefined
			for innerValue in value
				Cache = @analize Cache, cssProperty, innerValue
		else
			for key, innerValue of value
				Cache[key] = []
				Cache[key] = @analize Cache[key], cssProperty, innerValue
		return Cache

	updateStyles: (propertysObj) ->
		return

	# UTILITYS
	@utils:
		# constants
		NUMERIC: "NUMERIC"
		COLOR: "COLOR"
		STRING: "STRING"

		PREFIX: ['','-ms-','-moz-','-o-','-webkit-']

		apply: (obj, config) ->
			obj[key] = config[key] for key,value of config 
			return obj

		applyIf: (obj, config) ->
			for key, value of config
				if typeof obj[key] is 'undefined'
					obj[key] = config[key]
			return obj

		getType: (str) ->
			if /(px|\%|em|pt|pc|in|rem|cm|mm|rad|deg|s|ms|^\d+)$/gi.test str
				@NUMERIC
			else if /\#[0-9a-f]{3}/gi.test str or /\#[0-9a-fA-F]{6}/gi.test str
				@COLOR
			else
				@STRING

		getTypeExt: (type, value)->
			switch type
				when @NUMERIC
					if /(px|\%|em|pt|pc|in|rem|cm|mm|rad|deg|s|ms)/gi.test value
						value.replace /.*?(px|\%|em|pt|pc|in|rem|cm|mm|rad|deg|s|ms)$/gi, '$1'
					else
						""
				when @COLOR
					"#"
				else
					""
		convertHexColorToDec: (value)->
			value = value.substr 1
			if value.length is 3
				a = value.substr(0,1)
				b = value.substr(1,1)
				c = value.substr(2,1)
				value = a+a+b+b+c+c
			return {
				r: parseInt(value.substr(0, 2), 16)
				g: parseInt(value.substr(2, 2), 16)
				b: parseInt(value.substr(4, 2), 16)
			}

		convertDecColorToHex: (value)->
			value.r = value.r.toString(16) + if value.r < 16 then "0" else ""
			value.g = value.g.toString(16) + if value.g < 16 then "0" else ""
			value.b = value.b.toString(16) + if value.b < 16 then "0" else ""
			return '#' + value.r + value.g + value.b

		needPrefixFix: (cssProperty)->
			/^-prefix-/gi.test cssProperty


window.Animator = Animator

###
////////////////////////////////////////// usage \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
// using jquery
Animator.prototype.updateStyles = function(propertysObj){
	$(this.el).css(propertysObj);
}
test = new Animator(".first", {
		'left': ['5.5%']
	}, {
		'left': ['-31%']
	}
	,750);
test.start();
###