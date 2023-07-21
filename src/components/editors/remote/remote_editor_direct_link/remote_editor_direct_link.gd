extends ConfirmationDialogAutoFree

signal link_confirmed(link)

@onready var _url_edit: LineEdit = %UrlEdit


func _ready() -> void:
	super._ready()
	_update_ok_button_availability()
	_url_edit.text_changed.connect(func(_arg): 
		_update_ok_button_availability()
	)
	confirmed.connect(func():
		link_confirmed.emit(_url_edit.text)
	)
	_url_edit.custom_minimum_size = Vector2(300, 0) * Config.EDSCALE


func _update_ok_button_availability():
	get_ok_button().disabled = _url_edit.text.is_empty()
