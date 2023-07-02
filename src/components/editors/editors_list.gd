extends VBoxContainer


func _ready():
	theme_changed.connect(_update_theme)


func _update_theme():
	$ScrollContainer.set(
		"theme_override_styles/panel",
		get_theme_stylebox("panel", "EditorsListScrollContainer")
	)
