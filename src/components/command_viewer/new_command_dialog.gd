class_name CommandViewerNewCommandDialog
extends ConfirmationDialogAutoFree

signal created(command_name: String, path: String, args: PackedStringArray, icon: String, is_local: bool)

@onready var _name_edit := %NameEdit as LineEdit
@onready var _args_edit := %ArgsEdit as ArrayEdit
@onready var _is_local_checkbox := %IsLocalCheckbox as CheckBox
@onready var _path_edit := %PathEdit as LineEdit
@onready var _icon_edit := %IconEdit as LineEdit
@onready var _icon_rect := %IconRect as TextureRect


var name_text: String:
	get: return _name_edit.text.strip_edges()


var args_array: PackedStringArray:
	get: return _args_edit.get_array()


var path: String:
	get: return _path_edit.text.strip_edges()


var icon: String:
	get: return _icon_edit.text.strip_edges()


var is_local: bool:
	get: return _is_local_checkbox.button_pressed


func _ready() -> void:
	min_size = Vector2(250, 0) * Config.EDSCALE
	
	confirmed.connect(func() -> void:
		created.emit(name_text, path, args_array, icon, is_local)
	)
	_icon_edit.focus_exited.connect(_reload_icon)


func init(cmd_name: String, cmd_path: String, cmd_args: PackedStringArray, cmd_icon: String, is_local: bool) -> void:
	_name_edit.text = cmd_name
	_path_edit.text = cmd_path
	_icon_edit.text = cmd_icon
	_args_edit.override_array(cmd_args)
	_is_local_checkbox.button_pressed = is_local
	_reload_icon()


func _process(delta: float) -> void:
	var ok_button := get_ok_button()
	ok_button.disabled = name_text.is_empty() or len(args_array) == 0


func _reload_icon() -> void:
	_icon_rect.texture = get_theme_icon(icon, "EditorIcons")
