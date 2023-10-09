class_name CliOpenEditor

static func to_query(cmd: CliParser.ParsedCommandResult, user_args: PackedStringArray):
	var name = cmd.names.front()
	name = cmd.get_first_present_option_value(["name", "n"]) if name == "" else name
	var tags = cmd.get_first_present_option_values(["tags", "t"])
	var auto_detect = cmd.has_options(["auto", "a"])

	return Query.new(name, user_args, auto_detect)

class Query extends RefCounted:
	var name: String
	var auto_detect: bool
	var tags: Array[String] = []

	var args: PackedStringArray

	func _init(name: String, editor_args: PackedStringArray, auto_detect: bool = false, tags: Array[String] = []):
		self.name = name
		self.args = editor_args
		self.auto_detect = auto_detect
		self.tags = tags

class Command extends RefCounted:
	var _editors: EditorTypes.LocalEditors
	
	func _init(editors: EditorTypes.LocalEditors):
		_editors = editors
	
	func execute(query: Query):
		_editors.load()
	
		var editors = _editors.filter_by_name_pattern(query.name)
		if editors.size() == 1:
			Output.push("Editor is found by path: %s " % editors[0].path)
			editors[0].open(query.args)
		elif editors.size() > 1:
			Output.push("There is ambiguity between editors to run.")
		else:
			Output.push("Required engine is not found!")
