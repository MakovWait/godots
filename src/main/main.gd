extends Control

const theme_source = preload("res://theme/theme.gd")


@export var _remote_editors: Control
@export var _local_editors: Control

@onready var _gui_base: Panel = get_node("%GuiBase")
@onready var _main_v_box: VBoxContainer = get_node("%MainVBox")

const EDITORS_CONFIG_PATH = "user://editors.cfg"
var _editors = ConfigFile.new()


func _ready():
	_editors.load(EDITORS_CONFIG_PATH)

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
		get_theme_constant("window_border_margin", "Editor")
	)
	_main_v_box.add_theme_constant_override(
		"separation", 
		get_theme_constant("top_bar_separation", "Editor")
	)

	_remote_editors.installed.connect(func(name, path):
		if not _editors.has_section(path):
			_editors.set_value(path, "name", name)
			_editors.save(EDITORS_CONFIG_PATH)
	)
	
	_local_editors.update_items(_editors)


func _enter_tree():
	theme_source.set_scale(Config.EDSCALE)
	theme = theme_source.create_editor_theme(null)
	
	var window = get_window()
	window.min_size = Vector2(520, 350) * Config.EDSCALE
	window.size = window.min_size
