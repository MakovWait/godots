extends TextureRect


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	custom_minimum_size = Vector2(64, 64) * Config.EDSCALE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
