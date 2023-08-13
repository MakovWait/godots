extends HBoxContainer

const Projects = preload("res://src/services/projects.gd")

signal manage_tags_requested(item_tags, all_tags, on_confirm)

@onready var _sidebar: VBoxContainer = $ActionsSidebar
@onready var _projects_list: VBoxContainer = $ProjectsList
@onready var _import_project_button: Button = %ImportProjectButton
@onready var _import_project_dialog: ConfirmationDialog = $ImportProjectDialog
@onready var _new_project_button = %NewProjectButton
@onready var _new_project_dialog = $NewProjectDialog

var _projects: Projects.Projects
var _load_projects_queue = []


func init(projects: Projects.Projects):
	self._projects = projects
	
	_import_project_button.icon = get_theme_icon("Load", "EditorIcons")
	_import_project_button.pressed.connect(func(): import())
	_import_project_dialog.imported.connect(func(project_path, editor_path):
		var project
		if projects.has(project_path):
			project = projects.retrieve(project_path)
			project.editor_path = editor_path
			project.emit_internals_changed()
		else:
			project = _projects.add(project_path, editor_path)
			project.load()
			_projects_list.add(project)
		_projects.save()
		_projects_list.sort_items()
	)
	
	_new_project_dialog.created.connect(func(project_path):
		import(project_path)
	)
	_new_project_button.pressed.connect(_new_project_dialog.raise)
	_new_project_button.icon = get_theme_icon("Add", "EditorIcons")
	
	_projects_list.refresh(_projects.all())
	_load_projects()


func _load_projects():
	for project in _projects.all():
		project.load()
		await get_tree().process_frame
	_projects_list.sort_items()


func import(project_path=""):
	if _import_project_dialog.visible:
		return
	_import_project_dialog.init(project_path, _projects.get_editors_to_bind())
	_import_project_dialog.popup_centered()


func _on_projects_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_projects_list_item_removed(item_data) -> void:
	if _projects.has(item_data.path):
		_projects.erase(item_data.path)
		_projects.save()
	_sidebar.refresh_actions([])


func _on_projects_list_item_edited(item_data) -> void:
	item_data.emit_internals_changed()
	_projects.save()
	_projects_list.sort_items()


func _on_projects_list_item_manage_tags_requested(item_data) -> void:
	var all_tags = Set.new()
	all_tags.append_array(_projects.get_all_tags())
	all_tags.append_array(Config.DEFAULT_PROJECT_TAGS)
	manage_tags_requested.emit(
		item_data.tags,
		all_tags.values(),
		func(new_tags):
			item_data.tags = new_tags
			_on_projects_list_item_edited(item_data)
	)
