class_name CompInit


static func SET_FOCUS(mode):
	return func(c: Control): c.focus_mode = mode


static func SET_FLAT(value=true):
	return func(c): c.flat = value


static func TOOLTIP_TEXT(text):
	return func(c): c.tooltip_text = c.tr(str(text))


static func THEME_CHANGED(callback):
	return func(c: Control): c.theme_changed.connect(func(): callback.call(c))


static func TREE_ENTERED(callback):
	return func(c: Control): c.tree_entered.connect(func(): callback.call(c))


static func ADD_THEME_STYLEBOX_OVERRIDE_FROM_THEME(name, theme_stylebox_name, theme_type):
	return func(c: Control): c.add_theme_stylebox_override(
		name, c.get_theme_stylebox(theme_stylebox_name, theme_type)
	)


static func ADD_THEME_STYLEBOX_OVERRIDE(name, stylebox):
	return func(c: Control): c.add_theme_stylebox_override(name, stylebox)


static func SIZE_FLAGS_HORIZONTAL(v):
	return func(c): c.size_flags_horizontal = v


static func SIZE_FLAGS_HORIZONTAL_EXPAND_FILL():
	return SIZE_FLAGS_HORIZONTAL(Control.SIZE_EXPAND_FILL)


static func TEXT(t):
	return func(c): c.text = c.tr(str(t))


static func CUSTOM(callback):
	return callback


static func MERGED(callbacks):
	return func(x): 
		for callback in callbacks:
			callback.call(x)
