extends ConfirmationDialogAutoFree

signal link_confirmed(link)

@onready var _url_edit: LineEdit = %UrlEdit


func _ready() -> void:
	super._ready()
	_url_edit.text_changed.connect(func(_arg): 
		_update_ok_button_availability()
	)
	confirmed.connect(func():
		link_confirmed.emit(_url_edit.text)
	)


func _update_ok_button_availability():
	get_ok_button().disabled = _url_edit.text.is_empty()
