class_name CliGrammar

var _commands = []

func _init(commands: Array[CliCommand]):
	self._commands = commands

func flag_name_forms(namesp: String, verb: String, flag: String) -> Array[String]:
	var command = _find_command(namesp, verb)
	if command:
		for option in command.options:
			if option.long == flag or option.short == flag:
				return [option.long, option.short]
	return []

func supports_flag(namesp: String, verb: String, flag: String) -> bool:
	var command = _find_command(namesp, verb)
	if command:
		for option in command.options:
			if option.long == flag or option.short == flag:
				return true
	return false

func supports_verb(namesp: String, verb: String) -> bool:
	return _find_command(namesp, verb) != null

func supports_namespace(namesp: String) -> bool:
	for command in _commands:
		if command.namesp == namesp:
			return true
	return false

func namespaces() -> Array[String]:
	var namespaces: Array[String] = []
	for command in _commands:
		if not namespaces.has(command.namesp):
			namespaces.append(command.namesp)
	return namespaces

func verbs(ns: String) -> Array[String]:
	var verbs: Array[String] = []
	for command in _commands:
		if command.namesp == ns:
			verbs.append(command.verb)
	return verbs

func _find_command(namesp: String, verb: String) -> CliCommand:
	for command in _commands:
		if command.namesp == namesp and command.verb == verb:
			return command
	return null
