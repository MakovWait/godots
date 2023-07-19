extends TextureButton


func _ready() -> void:
#	texture_normal = get_theme_icon("NonFavorite", "EditorIcons")
#	texture_pressed = get_theme_icon("Favorites", "EditorIcons")
	
	texture_normal = get_theme_icon("Favorites", "EditorIcons")
	toggle_mode = true

	_update_modualate()
	toggled.connect(func(_arg): _update_modualate())


func _update_modualate():
	modulate = Color(1, 1, 1, 1) if button_pressed else Color(1, 1, 1, 0.2)
