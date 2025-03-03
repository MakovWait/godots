class_name RenameEditorDialog
extends ConfirmationDialogAutoFree

signal editor_renamed(new_name: String, version_tag: String)

@onready var _name_edit: LineEdit = %LineEdit
@onready var _version_hint_edit: LineEdit = %LineEdit2


func _ready() -> void:
	super._ready()
	
	min_size = Vector2(350, 0) * Config.EDSCALE
	
	confirmed.connect(func() -> void:
		editor_renamed.emit(
			_name_edit.text.strip_edges(), 
			_version_hint_edit.text.strip_edges()
		)
	)
	
	_name_edit.text_changed.connect(func(new_text: String) -> void:
		get_ok_button().disabled = new_text.strip_edges().is_empty()
	)


func init(initial_name: String, initial_version_hint: String) -> void:
	_name_edit.text = initial_name
	_version_hint_edit.text = initial_version_hint
