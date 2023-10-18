class_name CliMain

static func execute(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
	if cmd.namesp == "" and cmd.verb == "":
		Help.new().print_commands(GodotsCommands.commands)

static func main(args: PackedStringArray, app_args: PackedStringArray):
	if (args.size() >= 1):

		var parser = CliParser.CommandParser.new(CliGrammar.new(GodotsCommands.commands))
		var cmd = parser.parse_command(args)

		if not cmd.has_error():
			execute(cmd, app_args)
		else:
			Output.push("Errors: \n" + "\t\n".join(cmd.errors))
	pass
