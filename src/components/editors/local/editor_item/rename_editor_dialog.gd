extends ConfirmationDialogAutoFree

signal editor_renamed(new_name, version_tag)

@onready var _name_edit: LineEdit = %LineEdit
@onready var _version_hint_edit = %LineEdit2


func _ready() -> void:
	super._ready()
	
	min_size = Vector2(350, 0) * Config.EDSCALE
	
	confirmed.connect(func():
		editor_renamed.emit(
			_name_edit.text.strip_edges(), 
			_version_hint_edit.text.strip_edges()
		)
	)
	
	_name_edit.text_changed.connect(func(new_text):
		get_ok_button().disabled = new_text.strip_edges().is_empty()
	)


func init(initial_name, initial_version_hint):
	_name_edit.text = initial_name
	_version_hint_edit.text = initial_version_hint
