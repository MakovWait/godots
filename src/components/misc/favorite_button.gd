extends TextureButton


func _ready() -> void:
	texture_normal = get_theme_icon("NonFavorite", "EditorIcons")
	texture_pressed = get_theme_icon("Favorites", "EditorIcons")
	toggle_mode = true
