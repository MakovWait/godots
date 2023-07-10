static func simple(text, icon, on_pressed):
	var btn = Button.new()
	btn.icon = icon
	btn.text = text
	btn.pressed.connect(on_pressed)
	return btn
