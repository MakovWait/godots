class_name CliMain

static func execute(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
	if cmd.namesp == "editor" and cmd.verb == "exec":
		var editors = EditorTypes.LocalEditors.new(Config.EDITORS_CONFIG_PATH)
		CliOpenEditor.Command.new(editors).execute(CliOpenEditor.to_query(cmd, user_args))
	else:
		pass

static func main(args: PackedStringArray, app_args: PackedStringArray):
	if (args.size() >= 1):
		var ghelp_option = CliOption.new("--ghelp", "", "Global Help", "godots.exe --ghelp")
		var tags_option = CliOption.new("--tags", "-t", "Tag Specification", "godots.exe --tags <my_tag1>*")
		var auto_option = CliOption.new("--auto", "-a", "Auto mode", "")
		var name_option = CliOption.new("--name", "-n", "Name Specification", "--name|-n 4.1.1")

		var exec_command = CliCommand.new("editor", "exec", "Execute Command", "Usage for execute", [tags_option, auto_option, name_option])
		var global_command = CliCommand.new("", "", "Global Command", "Usage for global command", [ghelp_option])

		var commands: Array[CliCommand] = [
			exec_command,
			global_command
		]

		var parser = CliParser.CommandParser.new(CliGrammar.new(commands))
		var cmd = parser.parse_command(args)

		if not cmd.has_error():
			execute(cmd, app_args)
		else:
			Output.push("Errors: \n" + "\t\n".join(cmd.errors))
	pass
