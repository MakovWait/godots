extends ConfirmationDialogAutoFree

signal editor_renamed(new_name)

@onready var _line_edit: LineEdit = %LineEdit


func _ready() -> void:
	super._ready()
	
	min_size = Vector2(300, 0) * Config.EDSCALE
	
	confirmed.connect(func():
		editor_renamed.emit(_line_edit.text.strip_edges())
	)
	
	_line_edit.text_changed.connect(func(new_text):
		get_ok_button().disabled = new_text.strip_edges().is_empty()
	)


func init(initial_name):
	_line_edit.text = initial_name
