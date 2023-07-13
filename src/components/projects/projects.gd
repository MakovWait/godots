extends HBoxContainer

const Projects = preload("res://src/services/projects.gd")

@onready var _sidebar: VBoxContainer = $ActionsSidebar
@onready var _projects_list: VBoxContainer = $ProjectsList
@onready var _import_project_button: Button = %ImportProjectButton
@onready var _import_project_dialog: ConfirmationDialog = $ImportProjectDialog

var _projects: Projects.Projects


func init(projects: Projects.Projects):
	self._projects = projects
	
	_import_project_button.icon = get_theme_icon("Load", "EditorIcons")
	_import_project_button.pressed.connect(func():
		_import_project_dialog.init(_projects.get_editors_to_bind())
		_import_project_dialog.popup_centered()
	)
	_import_project_dialog.imported.connect(func(project_path, editor_path):
		var project
		if projects.has(project_path):
			project = projects.retrieve(project_path)
			project.editor_path = editor_path
			project.emit_internals_changed()
		else:
			project = _projects.add(project_path, editor_path)
			_projects_list.add(project)
		_projects.save()
		_projects_list.sort_items()
	)
	
	_projects_list.refresh(_projects.all())
	_projects_list.sort_items()


func _on_projects_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_projects_list_item_removed(item_data) -> void:
	if _projects.has(item_data.path):
		_projects.erase(item_data.path)
		_projects.save()
	_sidebar.refresh_actions([])


func _on_projects_list_item_edited(item_data) -> void:
	_projects.save()
	_projects_list.sort_items()
