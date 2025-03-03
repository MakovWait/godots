extends HBoxContainer

@onready var _local := %Local as Button
@onready var _remote := %Remote as Button


func _ready() -> void:
	var ctx := Context.use(self, LocalRemoteEditorsSwitchContext) as LocalRemoteEditorsSwitchContext
	ctx.changed.connect(func() -> void:
		_local.button_pressed = ctx.local_is_selected()
		_remote.button_pressed = ctx.remote_is_selected()
	)
	_local.pressed.connect(func() -> void:
		ctx.go_to_local()
		_local.set_pressed_no_signal(true)
	)
	_remote.pressed.connect(func() -> void:
		ctx.go_to_remote()
		_local.set_pressed_no_signal(true)
	)
	
	add_theme_constant_override("separation", 48 * Config.EDSCALE)
	
	_set_theme_to(_local)
	_set_theme_to(_remote)


func _set_theme_to(btn: Control) -> void:
	btn.add_theme_font_override("font", get_theme_font("main_button_font", "EditorFonts"))
	btn.add_theme_font_size_override("font_size", get_theme_font_size("main_button_font_size", "EditorFonts"))
