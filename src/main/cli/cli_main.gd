class_name CliMain

static func main(args: PackedStringArray, app_args: PackedStringArray) -> void:
	if (args.size() >= 1):
		var parser := CliParser.CommandParser.new(CliGrammar.new(GodotsCommands.commands))
		var cmd := parser.parse_command(args)

		if not cmd.has_error():
			var ctx := CliContext.new()
			var root := RootRoutes.new(ctx)
			if root.match(cmd, app_args):
				root.route(cmd, app_args)
			else:
				Output.push("Invalid command!")
			ctx.cleanup()
		else:
			Output.push("Errors: \n" + "\t\n".join(cmd.errors))
	pass
