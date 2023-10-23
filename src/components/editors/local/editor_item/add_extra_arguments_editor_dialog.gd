extends ConfirmationDialogAutoFree

signal editor_add_extra_arguments(new_name)

@onready var _line_edit: LineEdit = %LineEdit


func _ready() -> void:
	super._ready()
	min_size = Vector2(300, 0) * Config.EDSCALE
	
	confirmed.connect(func():
		editor_add_extra_arguments.emit(_line_edit.text.strip_edges())
	)

func init(initial_name):
	_line_edit.text = initial_name


