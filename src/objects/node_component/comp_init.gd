class_name CompInit


static func SET_FOCUS(mode: Control.FocusMode) -> Callable:
	return func(c: Control) -> void: c.focus_mode = mode


static func SET_FLAT(value:=true) -> Callable:
	return func(c: Control) -> void: c.set("flat", value)


static func TOOLTIP_TEXT(text: Variant) -> Callable:
	return func(c: Control) -> void: c.set("tooltip_text", c.tr(str(text)))


static func SET_EDITABLE(v: bool) -> Callable:
	return func(c: Control) -> void: c.set("editable", v)


static func SET_META(n: String, v: Variant) -> Callable:
	return func(c: Control) -> void: c.set_meta(n, v)


static func SET_THEME_ICON(name: String, theme_type: String) -> Callable:
	return func(c: Control) -> void: c.set("icon", c.get_theme_icon(name, theme_type))


static func SET_BUTTON_GROUP(btn_group: ButtonGroup) -> Callable:
	return func(c: Control) -> void: c.set("button_group", btn_group)


static func THEME_CHANGED(callback: Callable) -> Callable:
	return func(c: Control) -> void: c.connect("theme_changed", func() -> void: callback.call(c))


static func TREE_ENTERED(callback: Callable) -> Callable:
	return func(c: Control) -> void: c.connect("tree_entered", func() -> void: callback.call(c))


static func PRESSED(callback: Callable) -> Callable:
	return func(c: Control) -> void: c.connect("pressed", func() -> void: callback.call(c))


static func ADD_THEME_STYLEBOX_OVERRIDE_FROM_THEME(name: String, theme_stylebox_name: String, theme_type: String) -> Callable:
	return func(c: Control) -> void: c.add_theme_stylebox_override(
		name, c.get_theme_stylebox(theme_stylebox_name, theme_type)
	)


static func ADD_THEME_STYLEBOX_OVERRIDE(name: String, stylebox: StyleBox) -> Callable:
	return func(c: Control) -> void: c.add_theme_stylebox_override(name, stylebox)


static func SIZE_FLAGS_HORIZONTAL(v: Control.SizeFlags) -> Callable:
	return func(c: Control) -> void: c.size_flags_horizontal = v


static func SIZE_FLAGS_HORIZONTAL_EXPAND_FILL() -> Callable:
	return SIZE_FLAGS_HORIZONTAL(Control.SIZE_EXPAND_FILL)


static func TEXT(t: Variant) -> Callable:
	return func(c: Control) -> void: c.set("text", c.tr(str(t))) 


static func VALUE(v: Variant) -> Callable:
	return func(c: Control) -> void: c.set("value", v)


static func CUSTOM(callback: Callable) -> Callable:
	return callback


static func MERGED(callbacks: Array) -> Callable:
	return func(x: Control) -> void: 
		for callback: Callable in callbacks:
			callback.call(x)
