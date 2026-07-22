class_name OpenTemplateDialog
extends ConfirmationDialog

signal opened(project_name: String, target_path: String, template_item: ProjectTemplates.Item)

@onready var _project_name_edit: LineEdit = %ProjectNameEdit
@onready var _project_path_edit: LineEdit = %ProjectPathLineEdit
@onready var _browse_path_button: Button = %BrowsePathButton
@onready var _create_folder_check: CheckButton = %CreateFolderCheck
@onready var _message_label: Label = %MessageLabel
@onready var _status_rect: TextureRect = %StatusRect
@onready var _file_dialog: FileDialog = $FileDialog

var _template_item: ProjectTemplates.Item
var _auto_dir: String = ""


func _ready() -> void:
	dialog_hide_on_ok = false
	_browse_path_button.icon = get_theme_icon("Load", "EditorIcons")
	
	_project_name_edit.text_changed.connect(func(_arg: String) -> void:
		_update_project_dir()
		_validate()
	)
	_project_path_edit.text_changed.connect(func(_arg: String) -> void: _validate())
	
	_browse_path_button.pressed.connect(func() -> void:
		var path := _project_path_edit.text.strip_edges()
		if _create_folder_check.button_pressed:
			_file_dialog.current_dir = path.get_base_dir()
		else:
			_file_dialog.current_dir = path
		_file_dialog.popup_centered_ratio(0.5)
	)
	
	_file_dialog.dir_selected.connect(func(dir: String) -> void:
		if _create_folder_check.button_pressed:
			var folder := _project_path_edit.text.get_file()
			if folder != _auto_dir:
				folder = _auto_dir
			_project_path_edit.text = dir.path_join(folder)
		else:
			_project_path_edit.text = dir
		_validate()
	)
	
	_create_folder_check.toggled.connect(func(pressed: bool) -> void:
		var path := _project_path_edit.text
		if pressed:
			path = path.path_join(_auto_dir)
		else:
			path = path.rstrip("/\\")
			if path.get_file() == _auto_dir:
				pass
			else:
				pass
			path = path.get_base_dir()
		_project_path_edit.text = path
		_validate()
	)
	
	confirmed.connect(func() -> void:
		var project_name := _project_name_edit.text.strip_edges()
		var target_path := _project_path_edit.text.strip_edges()
		
		if _create_folder_check.button_pressed:
			DirAccess.make_dir_recursive_absolute(target_path)
		
		opened.emit(project_name, target_path, _template_item)
		hide()
	)
	
	min_size = Vector2(640, 200) * Config.EDSCALE


func raise(template_item: ProjectTemplates.Item) -> void:
	_template_item = template_item
	_project_name_edit.text = template_item.name
	_project_path_edit.text = Config.DEFAULT_PROJECTS_PATH.ret()
	_auto_dir = ""
	_validate()
	popup_centered()
	_project_name_edit.grab_focus()
	_project_name_edit.select_all()
	_update_project_dir()


func _update_project_dir() -> void:
	var project_name := _project_name_edit.text.strip_edges()
	var new_auto_dir := project_name.to_snake_case().validate_filename()
	if _create_folder_check.button_pressed:
		var path := _project_path_edit.text
		if path.get_file() == _auto_dir or _auto_dir.is_empty():
			_project_path_edit.text = path.get_base_dir().path_join(new_auto_dir)
	_auto_dir = new_auto_dir
	_validate()


func _validate() -> void:
	var project_name := _project_name_edit.text.strip_edges()
	var path := _project_path_edit.text.strip_edges()
	
	if project_name.is_empty():
		_error(tr("Project name cannot be blank."))
		return
	
	if path.is_empty():
		_error(tr("Target path cannot be blank."))
		return
	
	if _create_folder_check.button_pressed:
		_success(tr("The project folder will be automatically created."))
		return
	
	var dir := DirAccess.open(path)
	if not dir:
		_error(tr("The path specified doesn't exist."))
		return
	
	_success(tr("Ready to create project from template."))


func _error(text: String) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))
	_status_rect.texture = get_theme_icon("StatusError", "EditorIcons")
	get_ok_button().disabled = true


func _success(text: String) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", get_theme_color("success_color", "Editor"))
	_status_rect.texture = get_theme_icon("StatusSuccess", "EditorIcons")
	get_ok_button().disabled = false
