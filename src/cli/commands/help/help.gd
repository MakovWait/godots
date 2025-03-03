class_name Help

class Route extends Routes.Item:
	func route(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> void:
		Help.new().execute(Request.new(GodotsCommands.commands))
	
	func match(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray) -> bool:
		return cmd.args.has_options(["ghelp", "gh"])

class Request:
	var commands: Array[CliCommand]
	
	func _init(commands: Array[CliCommand]) -> void:
		self.commands = commands

func execute(req: Request) -> void:
	var commands_by_namespace: Dictionary[String, Array] = {}

	for command in req.commands:
		if not commands_by_namespace.has(command.namesp):
			commands_by_namespace[command.namesp] = []
		commands_by_namespace[command.namesp].append(command)

	if commands_by_namespace.has(""):
		var global_commands := commands_by_namespace[""].filter(func(c: CliCommand) -> bool: return c.verb.is_empty())
		if not global_commands.is_empty():
			Output.push("Usage: godots [arguments]")
			_print_commands(global_commands)
		var verb_commands := commands_by_namespace[""].filter(func(c: CliCommand) -> bool: return not c.verb.is_empty())
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

func _print_commands(commands: Array) -> void:
	var max_length := 0
	for cmd: CliCommand in commands:
		max_length = maxi(max_length, cmd.verb.length())
	for command: CliCommand in commands:
		Output.push(command.to_help_string(max_length))
		Output.push("")
