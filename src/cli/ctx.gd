class_name CliContext

var projects: Projects.List
var editors: LocalEditors.List


func _init():
	editors = LocalEditors.List.new(
		Config.EDITORS_CONFIG_PATH
	)
	projects = Projects.List.new(
		Config.PROJECTS_CONFIG_PATH,
		editors,
		preload("res://assets/default_project_icon.svg")
	)
	
	editors.load()
	projects.load()
