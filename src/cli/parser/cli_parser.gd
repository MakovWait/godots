class_name CliParser

static func _to_array_string(array: Array) -> Array[String]:
	var result: Array[String] = []
	result.append_array(array)
	return result

class ParsedOption:
	var long_name: String
	var short_name: String
	var failed: bool = false

	var values: Array[String] = []

	func _init(long, short, values: Array[String], failed):
		long_name = long
		short_name = short
		self.values = values
		self.failed = failed

	func has_name(name: String) -> bool:
		return name == long_name or name  == short_name

	func names_equal(option: ParsedOption) -> bool:
		return has_name(option.long_name) or has_name(option.short_name)

class ParsedCommandResult:
	var namesp: String
	var verb: String
	var options: Dictionary = {}
	var names: Array[String] = []
	var errors: Array[String] = []

	func _init(namesp: String, verb: String, options: Array[ParsedOption], names: Array[String]):
		self.namesp = namesp
		self.verb = verb
		self.names = names
		for option in options:
			self.options[option.long_name] = option
			self.options[option.short_name] = option

	func has_error() -> bool:
		return not errors.is_empty()

	func has_options(names: Array[String]) -> bool:
		for name in names:
			if options.has(name):
				return true
		return false

	func get_first_present_option_value(names: Array[String]) -> String:
		for name in names:
			if options.has(name) and not options[name].values.is_empty():
				return options[name].values.front()
		return ""

	func get_first_present_option_values(names: Array[String]) -> Array[String]:
		for name in names:
			if options.has(name):
				return options[name].values
		return []

	func option_value(name: String) -> String:
		if options.has(name) and not options[name].values.is_empty():
			return options[name].values.front()
		return ""

	func option_values(name: String) -> Array[String]:
		if options.has(name):
			return options[name].values
		return []

class CommandParser: 
	var _tokens : Array = []
	var current_token_index : int = 0

	var _grammar: CliGrammar

	var token:
		get: 
			if _has_tokens():
				return _tokens[current_token_index]
			return ""

	var _last_errors: Array[String] = []

	func _init(grammar: CliGrammar):
		self._grammar = grammar

	func parse_command(tokens: Array[String]) -> ParsedCommandResult:
		_tokens = tokens
		_last_errors = []
		current_token_index = 0

		var namesp = _expect_namespace()
		var verb = _expect_verb(namesp)
		var options: Array[ParsedOption] = []
		var names: Array[String] = _parse_names()

		while _has_tokens():
			var option: ParsedOption = _parse_option(namesp, verb)

			if option.failed:
				break;

			if options.any(func(o): return o.names_equal(option)):
				_raise_error("Only one option with name (`%s`, `%s`) can be used." % [option.long_name, option.short_name])
			else:
				options.append(option)

		var command = ParsedCommandResult.new(namesp, verb, options, names)
		command.errors = _last_errors
		return command

	func _parse_option(namesp: String, verb: String) -> ParsedOption:
		var long_name = ""
		var short_name = ""
		var values: Array[String] = []
		var failed = false

		if _is_option(token):
			if _grammar.supports_flag(namesp, verb, token):
				var name_forms = _grammar.flag_name_forms(namesp, verb, token)
				long_name = _adjust_flag_token_name(name_forms[0])
				short_name = _adjust_flag_token_name(name_forms[1])

				_next_token()
	
				while _has_tokens() and not _is_option(token):
					values.append(token)
					_next_token()
			else:
				_raise_error("Unsupported option: %s" % token)
				failed = true
				_next_token()
		else:
			_raise_error("Invalid token found instead of option name: %s" % token)
			failed = true
			_next_token()

		return ParsedOption.new(long_name, short_name, values, failed)

	func _parse_names() -> Array[String]:
		var result: Array[String] = []

		while _has_tokens() and not _is_option(token):
			result.append(token)
			_next_token()

		return result

	func _expect_namespace() -> String:
		if not _grammar.supports_namespace(token):
			return ""

		var result = token
		_next_token()
		return result

	func _expect_verb(scope: String) -> String:
		if not _grammar.supports_verb(scope, token):
			return ""

		var result = token;
		_next_token()
		return result

	func _adjust_flag_token_name(token: String) -> String:
		return token.substr(2, token.length()) if token.begins_with("--") else token.substr(1, token.length())

	func _is_option(token: String) -> bool:
		return token.begins_with("-")

	func _raise_error(message: String) -> void:
		_last_errors.push_back(message)

	func _next_token() -> void:
		current_token_index += 1

	func _has_tokens() -> bool:
		return current_token_index < _tokens.size()
