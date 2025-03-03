class_name EditorImportDialog
extends ConfirmationDialog

signal imported(editor_name: String, editor_path: String)

@onready var _name_edit: LineEdit = %NameEdit
@onready var _path_edit: LineEdit = %PathEdit
@onready var _browse_button: Button = %BrowseButton
@onready var _file_dialog: FileDialog = $FileDialog


func _ready() -> void:
#	super._ready()
	
	min_size = Vector2(300, 0) * Config.EDSCALE
	confirmed.connect(func() -> void: 
		imported.emit(_name_edit.text, _path_edit.text)
	)
	_browse_button.pressed.connect(func() -> void:
		_file_dialog.popup_centered_ratio(0.5)
		if _path_edit.text.is_empty():
			_file_dialog.current_dir = ProjectSettings.globalize_path(
				Config.VERSIONS_PATH.ret() as String
			)
		else:
			_file_dialog.current_path = _path_edit.text
	)
	_browse_button.icon = get_theme_icon("Load", "EditorIcons")
	_file_dialog.file_selected.connect(func(dir: String) -> void:
		_path_edit.text = dir
		_name_edit.text = utils.guess_editor_name(dir)
		_update_ok_button()
	)
	_file_dialog.dir_selected.connect(func(path: String) -> void:
		_path_edit.text = path
		_name_edit.text = utils.guess_editor_name(path)
	)
	_name_edit.text_changed.connect(func(_arg: String) -> void: _update_ok_button())
	_path_edit.text_changed.connect(func(_arg: String) -> void: _update_ok_button())
	
	if OS.has_feature("macos"):
		_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	else:
		_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE


func init(editor_name: String, exec_path: String) -> void:
	_name_edit.text = editor_name
	_path_edit.text = exec_path
	
	_update_ok_button()


func _update_ok_button() -> void:
	var should_be_disabled := _name_edit.text.is_empty() or _path_edit.text.is_empty()
	
	if OS.has_feature("windows"):
		should_be_disabled = should_be_disabled or not _path_edit.text.ends_with(".exe")
	elif OS.has_feature("macos"):
		should_be_disabled = should_be_disabled or not _path_edit.text.ends_with(".app")
	elif OS.has_feature("linux"):
		should_be_disabled = should_be_disabled or not FileAccess.file_exists(_path_edit.text)

	get_ok_button().disabled = should_be_disabled
