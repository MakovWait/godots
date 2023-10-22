class_name CliMain

static func execute(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
	if cmd.namesp == "" and cmd.verb == "":
		if cmd.args.has_options(["ghelp", "gh"]):
			Help.new().print_commands(GodotsCommands.commands)
		elif cmd.args.has_options(["recent", "r"]):
			OpenRecentProject.new().execute(OpenRecentProject.Request.new(user_args))
	elif cmd.namesp == "editor" and cmd.verb == "run":
		var name = cmd.args.first_option_value(["name", "n"])
		var working_dir = cmd.args.get_first_name(".") if name.is_empty() else ""
		OpenEditor.new().execute(OpenEditor.Request.new(name, user_args, working_dir))

static func main(args: PackedStringArray, app_args: PackedStringArray):
	if (args.size() >= 1):

		var parser = CliParser.CommandParser.new(CliGrammar.new(GodotsCommands.commands))
		var cmd = parser.parse_command(args)

		if not cmd.has_error():
			execute(cmd, app_args)
		else:
			Output.push("Errors: \n" + "\t\n".join(cmd.errors))
	pass
