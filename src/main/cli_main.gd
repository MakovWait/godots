class_name CliMain

static func main(args: PackedStringArray, editor_args: PackedStringArray):
	var parsed_args = _parse_args(args)
	
	if (parsed_args.size() >= 1):
		if "open" in parsed_args:
			CliOpenEditor.Command.new(
				EditorTypes.LocalEditors.new(Config.EDITORS_CONFIG_PATH)
			).execute(
				 CliOpenEditor.Query.new(
					parsed_args['open'],
					editor_args
				)
			)
		else:
			Output.push("Unsupported argument list: %s" % args.slice(0, args.size()))

	pass

static func _parse_args(args: PackedStringArray):
	var result = {}
	for argument in args:
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			result[key_value[0].lstrip("--")] = key_value[1]
		else:
			result[argument.lstrip("--")] = ""
	return result
