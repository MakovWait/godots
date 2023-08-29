extends Button

signal confirmed

var _popup: ConfirmationDialog


func _init():
	_popup = ConfirmationDialog.new()
	_popup.confirmed.connect(func(): confirmed.emit())
	_popup.dialog_text = tr("Remove all missing items from the list?\nThe item folders' contents won't be modified.")
	_popup.get_ok_button().text = tr("Remove All")
	add_child(_popup)
	
	pressed.connect(func():
		_popup.popup_centered()
	)


func _ready():
	text = tr("Remove Missing")


func _notification(what):
	if NOTIFICATION_THEME_CHANGED == what:
		icon = get_theme_icon("Clear", "EditorIcons")
