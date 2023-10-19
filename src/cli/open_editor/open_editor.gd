class_name OpenEditor

class Request:
	var name_pattern: String
	var user_args: PackedStringArray

	func _init(name_pattern: String, user_args: PackedStringArray):
		self.name_pattern = name_pattern
		self.user_args = user_args

var _editors: LocalEditors.List

func _init():
	_editors = LocalEditors.List.new(Config.EDITORS_CONFIG_PATH)

func execute(req: Request) -> void:
	if _editors.load() == Error.OK:
		var editors = _editors.filter_by_name_pattern(req.name_pattern)
		if editors.size() == 1:
			_run_editor(editors[0], req.user_args)
		elif editors.size() > 1:
			Output.push("There is ambiguity between editors to run.")
		else:
			Output.push("Required editor is not found!")
	else:
		Output.push("Some error happend during editors loading!")

func _run_editor(editor: LocalEditors.Item, user_args: PackedStringArray) -> void:
	Output.push("Editor is found by path: %s " % editor.path)
	Output.push("Run editor with args `%s`" % user_args)
	var pid = editor.as_process(user_args).create_process()
	
	if (pid == -1):
		Output.push('An error occured when create editor process')
