extends HBoxContainer

signal changed

@onready var _filter_edit = %FilterEdit
@onready var _search_button = %SearchButton


func _ready():
	_filter_edit.text_submitted.connect(func(new_text): changed.emit(true))
	_search_button.pressed.connect(func(): changed.emit(true))


func fill_params(params: AssetLib.Params):
	params.filter = _filter_edit.text.strip_edges()


func _update_search_button():
	_search_button.disabled = not _filter_edit.editable


func _on_fetch_disable():
	_filter_edit.editable = false
	_update_search_button()


func _on_fetch_enable():
	_filter_edit.editable = true
	_update_search_button()
