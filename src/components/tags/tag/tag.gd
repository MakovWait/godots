extends HBoxContainer

const UINT32_MAX = 0xFFFFFFFF

signal pressed

@onready var _color_rect: ColorRect = $ColorRect
@onready var _button: Button = $Button

var text := ""

func _ready() -> void:
	add_theme_constant_override("separation", 0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_button.pressed.connect(func(): pressed.emit())


func init(text: String, display_close: bool = false):
	self.text = text
	var tag_color = Color.from_ok_hsl(
		float(text.hash() * 10001 % UINT32_MAX) / float(UINT32_MAX), 
		0.8,
		0.5,
	)
	self_modulate = tag_color
	
	_color_rect.custom_minimum_size = Vector2(4, 0) * Config.EDSCALE
	_color_rect.color = tag_color
	
	_button.auto_translate = false
	_button.text = text.capitalize()
	_button.focus_mode = Control.FOCUS_NONE
	_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_button.theme_type_variation = "ProjectTag"
	
	if display_close:
		_button.icon = get_theme_icon("close", "TabBar")
