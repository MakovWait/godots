class_name OpenRecentProject

var _editors: LocalEditors.List
var _projects: Projects.List

func _init():
	_editors = LocalEditors.List.new(Config.EDITORS_CONFIG_PATH)
	_projects = Projects.List.new(
		Config.PROJECTS_CONFIG_PATH,
		_editors,
		null)

func execute() -> void:
	_editors.load()
	_projects.load()

	var project = _projects.get_last_opened()
	if project:
		project.load(false)
		project.edit()
	else:
		Output.push("Recent project does not exist.")

