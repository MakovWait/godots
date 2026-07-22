class_name ProjectTemplatesControl
extends HBoxContainer

@onready var _sidebar: ActionsSidebarControl = %ActionsSidebar
@onready var _templates_list: ProjectTemplatesVBoxList = %ProjectTemplatesList
@onready var _save_template_dialog: SaveTemplateDialog = %SaveTemplateDialog
@onready var _open_template_dialog: OpenTemplateDialog = %OpenTemplateDialog

var _templates: ProjectTemplates.List
var _projects_service: Projects.List


func init(templates: ProjectTemplates.List, projects_service: Projects.List) -> void:
	_templates = templates
	_projects_service = projects_service
	
	var actions := Action.List.new([
		Action.from_dict({
			"key": "save-template",
			"icon": Action.IconTheme.new(self, "Save", "EditorIcons"),
			"act": func() -> void: _save_template_dialog.raise(),
			"label": tr("Save as Template"),
		}),
		Action.from_dict({
			"key": "import-template",
			"icon": Action.IconTheme.new(self, "Load", "EditorIcons"),
			"act": _import_template,
			"label": tr("Import Template"),
		}),
		Action.from_dict({
			"key": "refresh",
			"icon": Action.IconTheme.new(self, "Reload", "EditorIcons"),
			"act": _refresh,
			"label": tr("Refresh List"),
		})
	])
	
	$ProjectTemplatesList/HBoxContainer.add_child(actions.by_key('refresh').to_btn().make_flat(true).show_text(false))
	$ProjectTemplatesList/HBoxContainer.add_child(actions.by_key('save-template').to_btn().make_flat(true).show_text(false))
	$ProjectTemplatesList/HBoxContainer.add_child(actions.by_key('import-template').to_btn().make_flat(true).show_text(false))
	
	_save_template_dialog.saved.connect(_on_save_template)
	_open_template_dialog.opened.connect(_on_open_template)
	
	_templates_list.refresh(_templates.all())
	_load_templates()


func _load_templates() -> void:
	for template: ProjectTemplates.Item in _templates.all():
		template.loaded.connect(func() -> void:
			_templates_list.sort_items()
		)
	_templates_list.sort_items()
	_templates_list.update_filters()


func _refresh() -> void:
	_templates.load()
	_templates_list.refresh(_templates.all())
	_load_templates()


func _on_save_template(template_name: String, description: String, source_path: String, tags: Array) -> void:
	var template := _templates.add(template_name, description, source_path, tags)
	_templates.save()
	
	# Create the zip from the source project
	var project_dir := source_path.get_base_dir()
	var err := _create_template_zip(project_dir, template.zip_path)
	if err != OK:
		Output.push("Failed to create template zip: %s" % err)
		return
	
	_templates_list.add(template)
	_templates_list.sort_items()


func _create_template_zip(source_dir: String, target_zip_path: String) -> Error:
	# Use zip command to create archive from source directory
	var output := []
	var exit_code: int
	
	# Ensure target directory exists
	DirAccess.make_dir_recursive_absolute(target_zip_path.get_base_dir())
	
	# Remove existing zip if present
	if FileAccess.file_exists(target_zip_path):
		DirAccess.remove_absolute(target_zip_path)
	
	if OS.has_feature("windows"):
		exit_code = OS.execute(
			"powershell.exe",
			[
				"-command",
				"Set-Location '%s'; Compress-Archive -Path '*' -DestinationPath '%s' -Force" % [
					source_dir,
					ProjectSettings.globalize_path(target_zip_path)
				]
			], output, true
		)
	else:
		exit_code = OS.execute(
			"bash",
			[
				"-c",
				"cd '%s' && zip -r '%s' ." % [
					source_dir,
					ProjectSettings.globalize_path(target_zip_path)
				]
			], output, true
		)
	
	Output.push(output.pop_front())
	Output.push("Template zip created with exit code: %s" % exit_code)
	return OK if exit_code == 0 else FAILED


func _on_open_template(project_name: String, target_path: String, template_item: ProjectTemplates.Item) -> void:
	if not template_item.is_zip_valid:
		Output.push("Template zip file is missing: %s" % template_item.zip_path)
		return
	
	# Unzip the template to the target path
	var zip_reader := ZIPReader.new()
	var unzip_err := zip_reader.open(template_item.zip_path)
	if unzip_err != OK:
		zip_reader.close()
		Output.push("Failed to open template zip: %s" % unzip_err)
		return
	
	var unzip_result := zip.unzip_to_path(zip_reader, target_path)
	zip_reader.close()
	
	if unzip_result != OK:
		Output.push("Failed to extract template: %s" % unzip_result)
		return
	
	# Find project.godot in the extracted files
	var project_configs := utils.find_project_godot_files(target_path)
	if len(project_configs) == 0:
		Output.push("No project.godot found in extracted template")
		return
	
	# Update the project name in project.godot
	var project_file_path := project_configs[0].path
	var cfg := ConfigFile.new()
	var err := cfg.load(project_file_path)
	if not err:
		cfg.set_value("application", "config/name", project_name)
		cfg.save(project_file_path)
	
	# Import the project into the projects list
	var project := _projects_service.add(project_file_path, "")
	project.load()
	_projects_service.save()
	
	_templates_list.sort_items()


func _import_template() -> void:
	# Import a template from a zip file
	var file_dialog := FileDialog.new()
	file_dialog.title = "Import Template Zip"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.zip ; Zip Files"])
	
	file_dialog.file_selected.connect(func(path: String) -> void:
		var template_name := path.get_file().replace(".zip", "").capitalize()
		var template := _templates.add(template_name, "Imported template", "", [])
		_templates.save()
		
		# Copy the zip file to the templates directory
		var err := DirAccess.copy_absolute(path, template.zip_path)
		if err != OK:
			Output.push("Failed to copy template zip: %s" % err)
			return
		
		_templates_list.add(template)
		_templates_list.sort_items()
	)
	
	add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.5)


func _on_templates_list_item_selected(item: TemplateListItemControl) -> void:
	pass


func _on_templates_list_item_removed(item_data: ProjectTemplates.Item) -> void:
	_templates.erase(item_data.id)
	_templates.save()
