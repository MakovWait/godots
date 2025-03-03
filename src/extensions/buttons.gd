class_name buttons

static func simple(text: String, icon: Texture2D, on_pressed: Callable) -> Button:
	var btn := Button.new()
	btn.icon = icon
	btn.text = text
	btn.pressed.connect(on_pressed)
	return btn
