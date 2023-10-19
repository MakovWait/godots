class_name CliParser

static func _to_array_string(array: Array) -> Array[String]:
	var result: Array[String] = []
	result.append_array(array)
	return result

class ParsedOption:
	var long_name: String
	var short_name: String

	var values: Array[String] = []

	func _init(long, short, values: Array[String]):
		long_name = long
		short_name = short
		self.values = values

	func has_name(name: String) -> bool:
		return name == long_name or name  == short_name

	func names_equal(option: ParsedOption) -> bool:
		return has_name(option.long_name) or has_name(option.short_name)

class ParsedArguments:
	var _options: Dictionary = {}

	var names: Array[String]

	func _init(names: Array[String], options: Array[ParsedOption]) -> void:
		self.names = names
		for option in options:
			_options[option.long_name] = option
			_options[option.short_name] = option

	func has_options(names: Array[String]) -> bool:
		for name in names:
			if _options.has(name):
				return true
		return false

	func first_option_value(names: Array[String]) -> String:
		return first_option_values(names).front()

	func first_option_values(names: Array[String]) -> Array[String]:
		for name in names:
			if _options.has(name):
				return _options[name].values
		return []

	func option_value(name: String) -> String:
		var result = option_values(name)
		return "" if result.is_empty() else result.front()
	
	func option_values(name: String) -> Array[String]:
		if _options.has(name):
			return _options[name].values
		return []

class ParsedCommandResult:
	var namesp: String
	var verb: String
	var args: ParsedArguments
	var errors: Array[String] = []

	func _init(namesp: String, verb: String, args: ParsedArguments):
		self.namesp = namesp
		self.verb = verb
		self.args = args

	func has_error() -> bool:
		return not errors.is_empty()

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
			var option = _parse_option(namesp, verb)

			if option == null:
				break;

			if options.any(func(o): return o.names_equal(option)):
				_raise_error("Only one option with name (`%s`, `%s`) can be used." % [option.long_name, option.short_name])
			else:
				options.append(option)

		var command = ParsedCommandResult.new(namesp, verb, ParsedArguments.new(names, options))
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
		
		if failed:
			return null
		else:
			return ParsedOption.new(long_name, short_name, values)

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
