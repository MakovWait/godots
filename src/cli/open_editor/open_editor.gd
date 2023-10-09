class_name CliOpenEditor

class Query extends RefCounted:
	var name: String
	var args: PackedStringArray
	
	func _init(name: String, editor_args: PackedStringArray):
		self.name = name
		self.args = editor_args
	
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
