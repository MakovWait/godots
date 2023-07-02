extends HBoxContainer


func _ready():
	$Favorite/FavoriteButton.texture_normal = get_theme_icon("Favorites", "EditorIcons")
	
	$Icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	$Icon.custom_minimum_size = Vector2(64, 64)
	$Icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
