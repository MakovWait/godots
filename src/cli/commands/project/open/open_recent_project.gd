class_name OpenRecentProject

class Request:
	var user_args: PackedStringArray
	
	func _init(user_args: PackedStringArray):
		self.user_args = user_args

var _editors: LocalEditors.List
var _projects: Projects.List

func _init():
	_editors = LocalEditors.List.new(Config.EDITORS_CONFIG_PATH)
	_projects = Projects.List.new(
		Config.PROJECTS_CONFIG_PATH,
		_editors,
		null)

func execute(req: Request) -> void:
	_editors.load()
	_projects.load()

	var project = _projects.get_last_opened()
	if project:
		project.load(false)
		project.edit(req.user_args)
	else:
		Output.push("Recent project does not exist.")

