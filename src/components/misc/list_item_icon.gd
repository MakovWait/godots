extends TextureRect


@export var _stretch_mode: StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	custom_minimum_size = Vector2(64, 64) * Config.EDSCALE
	stretch_mode = _stretch_mode
