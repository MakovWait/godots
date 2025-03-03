class_name AddExtraArgumentsEditorDialog
extends ConfirmationDialogAutoFree

signal editor_add_extra_arguments(args: PackedStringArray)

@onready var _array_edit := %ArrayEdit as ArrayEdit


func _ready() -> void:
	super._ready()
	min_size = Vector2(300, 0) * Config.EDSCALE
	
	confirmed.connect(func() -> void:
		editor_add_extra_arguments.emit(_array_edit.get_array())
	)


func init(initial_args: PackedStringArray) -> void:
	_array_edit.override_array(initial_args)
