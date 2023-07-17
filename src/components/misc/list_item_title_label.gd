extends Label


func _ready() -> void:
	clip_text = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(128, 0) * Config.EDSCALE
	add_theme_font_override(
		"font", get_theme_font("title", "EditorFonts")
	)
	add_theme_font_size_override(
		"font_size", get_theme_font_size("title_size", "EditorFonts")
	)
	add_theme_color_override(
		"font_color",
		get_theme_color("font_color", "Tree")
	)
