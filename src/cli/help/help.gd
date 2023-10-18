class_name Help

func print_commands(commands: Array[CliCommand]):
	var commands_by_namespace: Dictionary = {}

	for command in commands:
		if not commands_by_namespace.has(command.namesp):
			commands_by_namespace[command.namesp] = []
		commands_by_namespace[command.namesp].append(command)

	if commands_by_namespace.has(""):
		var global_commands = commands_by_namespace[""].filter(func(c): return c.verb.is_empty())
		if not global_commands.is_empty():
			Output.push("Usage: godots [arguments]")
			_print_commands(global_commands)
		var verb_commands = commands_by_namespace[""].filter(func(c): return not c.verb.is_empty())
		if not verb_commands.is_empty():
			Output.push("")
			Output.push("Usage: godots [command verb] [arguments]")
			_print_commands(verb_commands)

	commands_by_namespace.erase("")

	if not commands_by_namespace.is_empty():
		Output.push("")
		Output.push("Usage: godots [namespace] [verb] [arguments]")
		Output.push("")
		for nsp in commands_by_namespace:
			Output.push("%s ->" % nsp)
			_print_commands(commands_by_namespace[nsp])

func _print_commands(commands) -> void:
	var max_length = 0
	for cmd in commands:
		max_length = max(max_length, cmd.verb.length())
	for command in commands:
		Output.push(command.to_help_string(max_length))
		Output.push("")
