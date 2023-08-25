extends HBoxContainer

const Projects = preload("res://src/services/projects.gd")
const dir = preload("res://src/extensions/dir.gd")

signal manage_tags_requested(item_tags, all_tags, on_confirm)

@onready var _sidebar: VBoxContainer = $ScrollContainer/ActionsSidebar
@onready var _projects_list: VBoxContainer = $ProjectsList
@onready var _import_project_button: Button = %ImportProjectButton
@onready var _import_project_dialog: ConfirmationDialog = $ImportProjectDialog
@onready var _new_project_button = %NewProjectButton
@onready var _new_project_dialog = $NewProjectDialog
@onready var _scan_button = %ScanButton
@onready var _scan_dialog = %ScanDialog
@onready var _remove_missing_button = %RemoveMissingButton
@onready var _install_project_from_zip_dialog = $InstallProjectSimpleDialog
@onready var _duplicate_project_dialog = $DuplicateProjectDialog
@onready var _refresh_button = %RefreshButton


var _projects: Projects.Projects
var _load_projects_queue = []


func init(projects: Projects.Projects):
	self._projects = projects
	
	_import_project_button.icon = get_theme_icon("Load", "EditorIcons")
	_import_project_button.pressed.connect(func(): import())
	_import_project_dialog.imported.connect(add_project)
	
	_new_project_dialog.created.connect(func(project_path):
		import(project_path)
	)
	_new_project_button.pressed.connect(_new_project_dialog.raise)
	_new_project_button.icon = get_theme_icon("Add", "EditorIcons")
	
	_scan_button.icon = get_theme_icon("Search", "EditorIcons")
	_scan_button.pressed.connect(func():
		_scan_dialog.current_dir = ProjectSettings.globalize_path(
			Config.DEFAULT_PROJECTS_PATH.ret()
		)
		_scan_dialog.popup_centered_ratio(0.5)
	)
	_scan_dialog.dir_to_scan_selected.connect(func(dir_to_scan: String):
		_scan_projects(dir_to_scan)
	)
	
	_refresh_button.icon = get_theme_icon("Reload", "EditorIcons")
	_refresh_button.pressed.connect(_refresh)
	
	_remove_missing_button.confirmed.connect(_remove_missing)
	
	_projects_list.refresh(_projects.all())
	_load_projects()


func add_project(project_path: String, editor_path: String, edit: bool):
	var project
	if _projects.has(project_path):
		project = _projects.retrieve(project_path)
		project.editor_path = editor_path
		project.emit_internals_changed()
	else:
		project = _projects.add(project_path, editor_path)
		project.load()
		_projects_list.add(project)
	_projects.save()
	_projects_list.sort_items()
		
	if edit:
		project.run_with_editor('-e')
		AutoClose.close_if_should()


func _load_projects():
	_load_projects_array(_projects.all())


func _load_projects_array(array):
	for project in array:
		project.load()
		await get_tree().process_frame
	_projects_list.sort_items()
	_update_remove_missing_disabled()


func _refresh():
	_projects.load()
	_projects_list.refresh(_projects.all())
	_load_projects()


func import(project_path=""):
	if _import_project_dialog.visible:
		return
	_import_project_dialog.init(project_path, _projects.get_editors_to_bind())
	_import_project_dialog.popup_centered()


func install_zip(zip_reader: ZIPReader, project_name):
	if _install_project_from_zip_dialog.visible:
		zip_reader.close()
		return
	_install_project_from_zip_dialog.title = "Install Project: %s" % project_name
	_install_project_from_zip_dialog.get_ok_button().text = tr("Install")
	_install_project_from_zip_dialog.raise(project_name)
	_install_project_from_zip_dialog.dialog_hide_on_ok = false
	_install_project_from_zip_dialog.about_to_install.connect(func(final_project_name, project_dir):
		var unzip_err = zip.unzip_to_path(zip_reader, project_dir)
		zip_reader.close()
		if unzip_err != OK:
			_install_project_from_zip_dialog.error(tr("Failed to unzip."))
			return
		var project_configs = _find_project_godot_files(project_dir)
		if len(project_configs) == 0:
			_install_project_from_zip_dialog.error(tr("No project.godot found."))
			return
		
		var project_file_path = project_configs[0]
		_install_project_from_zip_dialog.hide()
		import(project_file_path.path)
		pass,
		CONNECT_ONE_SHOT
	)
	


func _scan_projects(dir_path):
	var project_configs = _find_project_godot_files(dir_path)
	var added_projects = []
	for project_config in project_configs:
		var project_path = project_config.path
		if _projects.has(project_path):
			continue
		var project = _projects.add(project_path, null)
		_projects_list.add(project)
		added_projects.append(project)
	_projects.save()
	_load_projects_array(added_projects)


func _find_project_godot_files(dir_path):
	var project_configs = dir.list_recursive(
		ProjectSettings.globalize_path(dir_path), 
		false,
		(func(x: dir.DirListResult): 
			return x.is_file and x.file == "project.godot"),
		(func(x: String): 
			return not x.get_file().begins_with("."))
	)
	return project_configs


func _remove_missing():
	for p in _projects.all().filter(func(x): return x.is_missing):
		_projects.erase(p.path)
	_projects.save()
	_projects_list.refresh(_projects.all())
	_projects_list.sort_items()
	_sidebar.refresh_actions([])
	_update_remove_missing_disabled()


func _update_remove_missing_disabled():
	_remove_missing_button.disabled = len(
		_projects.all().filter(func(x): return x.is_missing)
	) == 0


func _on_projects_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_projects_list_item_removed(item_data) -> void:
	if _projects.has(item_data.path):
		_projects.erase(item_data.path)
		_projects.save()
	_sidebar.refresh_actions([])
	_update_remove_missing_disabled()


func _on_projects_list_item_edited(item_data) -> void:
	item_data.emit_internals_changed()
	_projects.save()
	_projects_list.sort_items()


func _on_projects_list_item_manage_tags_requested(item_data) -> void:
	var all_tags = Set.new()
	all_tags.append_array(_projects.get_all_tags())
	all_tags.append_array(Config.DEFAULT_PROJECT_TAGS.ret())
	manage_tags_requested.emit(
		item_data.tags,
		all_tags.values(),
		func(new_tags):
			item_data.tags = new_tags
			_on_projects_list_item_edited(item_data)
	)


func _on_projects_list_item_duplicate_requested(project: Projects.Project) -> void:
	if _duplicate_project_dialog.visible:
		return
	
	_duplicate_project_dialog.title = "Duplicate Project: %s" % project.name
	_duplicate_project_dialog.get_ok_button().text = tr("Duplicate")
	
	_duplicate_project_dialog.raise(project.name)
	
	_duplicate_project_dialog.dialog_hide_on_ok = false
	_duplicate_project_dialog.about_to_install.connect(func(final_project_name, project_dir):
		var err = 0
		if OS.has_feature("macos") or OS.has_feature("linux"):
			err = OS.execute("cp", ["-r", project.path.get_base_dir().path_join("."), project_dir])
		elif OS.has_feature("windows"):
			err = OS.execute(
				"powershell.exe", 
				[
					"-command",
					"\"Copy-Item -Path '%s' -Destination '%s' -Recurse\"" % [ 
						ProjectSettings.globalize_path(project.path.get_base_dir().path_join("*")), 
						ProjectSettings.globalize_path(project_dir)
					]
				]
			)
		if err != 0:
			_duplicate_project_dialog.error(tr("Error. Code: %s" % err))
			return

		var project_configs = _find_project_godot_files(project_dir)
		if len(project_configs) == 0:
			_duplicate_project_dialog.error(tr("No project.godot found."))
			return
		
		var project_file_path = project_configs[0]
		_duplicate_project_dialog.hide()
		import(project_file_path.path)
		pass,
		CONNECT_ONE_SHOT
	)
