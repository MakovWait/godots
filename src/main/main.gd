extends Control

@onready var _gui_base : Panel = get_node("%GuiBase")
@onready var _main_v_box : VBoxContainer = get_node("%MainVBox")


func _ready():
	if not theme.default_font:
		theme.default_font = theme.get_font("main", "EditorFonts")
	
	if not theme.default_font_size == 0:
		theme.default_font_size = 14
	
	get_tree().root.content_scale_factor = Config.EDSCALE
	
	_gui_base.set(
		"theme_override_styles/panel",
		get_theme_stylebox("Background", "EditorStyles")
	)
	_gui_base.set_anchor(SIDE_RIGHT, Control.ANCHOR_END)
	_gui_base.set_anchor(SIDE_BOTTOM, Control.ANCHOR_END)
	_gui_base.set_end(Vector2.ZERO)
	
	_main_v_box.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT, 
		Control.PRESET_MODE_MINSIZE, 
		8 / Config.EDSCALE
	)
	_main_v_box.add_theme_constant_override(
		"separation", 
		8 / Config.EDSCALE
	)


func _enter_tree():
	var window = get_window()
	window.min_size = Vector2(1024, 600) * Config.EDSCALE
	window.size = window.min_size
