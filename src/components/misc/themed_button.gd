extends Button


@export var _theme_icon_name = "Load"
@export var _theme_type = "EditorIcons"


func _ready() -> void:
	_update_theme()
	theme_changed.connect(_update_theme)


func _update_theme():
	icon = get_theme_icon(_theme_icon_name, _theme_type)
