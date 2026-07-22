class_name SaveTemplateDialog
extends ConfirmationDialog

signal saved(template_name: String, description: String, source_path: String, tags: Array)

@onready var _template_name_edit: LineEdit = %TemplateNameEdit
@onready var _description_edit: TextEdit = %DescriptionEdit
@onready var _source_path_edit: LineEdit = %SourcePathEdit
@onready var _browse_source_button: Button = %BrowseSourceButton
@onready var _message_label: Label = %MessageLabel
@onready var _status_rect: TextureRect = %StatusRect
@onready var _file_dialog: FileDialog = $FileDialog


func _ready() -> void:
	dialog_hide_on_ok = false
	_browse_source_button.icon = get_theme_icon("Load", "EditorIcons")
	
	_source_path_edit.text_changed.connect(func(_arg: String) -> void: _validate())
	_template_name_edit.text_changed.connect(func(_arg: String) -> void: _validate())
	
	_browse_source_button.pressed.connect(func() -> void:
		_file_dialog.current_dir = _source_path_edit.text.strip_edges()
		_file_dialog.popup_centered_ratio(0.5)
	)
	
	_file_dialog.dir_selected.connect(func(dir: String) -> void:
		_source_path_edit.text = dir
		_validate()
	)
	
	confirmed.connect(func() -> void:
		var template_name := _template_name_edit.text.strip_edges()
		var description := _description_edit.text.strip_edges()
		var source_path := _source_path_edit.text.strip_edges()
		saved.emit(template_name, description, source_path, [])
		hide()
	)
	
	min_size = Vector2(640, 300) * Config.EDSCALE


func raise(source_project_path: String = "") -> void:
	_template_name_edit.text = ""
	_description_edit.text = ""
	_source_path_edit.text = source_project_path
	_validate()
	popup_centered()
	_template_name_edit.grab_focus()


func _validate() -> void:
	var template_name := _template_name_edit.text.strip_edges()
	var source_path := _source_path_edit.text.strip_edges()
	
	if template_name.is_empty():
		_error(tr("Template name cannot be blank."))
		return
	
	if source_path.is_empty():
		_error(tr("Source project path cannot be blank."))
		return
	
	var project_file := source_path.path_join("project.godot")
	if not FileAccess.file_exists(project_file):
		_error(tr("The selected path does not contain a project.godot file."))
		return
	
	_success(tr("Ready to save template."))


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
