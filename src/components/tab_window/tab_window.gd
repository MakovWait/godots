extends AcceptDialog

@onready var _tab_container = $TabContainer


func _ready():
	_tab_container.tabs_visible = false
	self.get_ok_button().hide()
	_update_theme()


func _update_theme():
	_tab_container.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT, 
		Control.PRESET_MODE_MINSIZE, 
		get_theme_constant("window_border_margin", "Editor")
	)

	self.set(
		"theme_override_styles/panel",
		get_theme_stylebox("Background", "EditorStyles")
	)
