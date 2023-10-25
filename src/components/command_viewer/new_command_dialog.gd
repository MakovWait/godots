class_name CommandViewerNewCommandDialog
extends ConfirmationDialogAutoFree

signal created(command_name: String, args: PackedStringArray, is_local: bool)

@onready var _name_edit = %NameEdit
@onready var _args_edit = %ArgsEdit as ArrayEdit
@onready var _is_local_checkbox = %IsLocalCheckbox


var name_text: String:
	get: return _name_edit.text.strip_edges()


var args_array: PackedStringArray:
	get: return _args_edit.get_array()


var is_local: bool:
	get: return _is_local_checkbox.button_pressed


func _ready():
	min_size = Vector2(250, 0) * Config.EDSCALE
	
	confirmed.connect(func():
		created.emit(name_text, args_array, is_local)
	)


func init(cmd_name, cmd_args):
	_name_edit.text = cmd_name
	_args_edit.override_array(cmd_args)


func _process(delta):
	var ok_button = get_ok_button()
	ok_button.disabled = name_text.is_empty() or len(args_array) == 0
