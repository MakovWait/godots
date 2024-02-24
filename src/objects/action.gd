class_name Action


static func from_dict(dict) -> Self:
	return Self.new(
		dict["key"],
		dict["label"],
		dict["icon"],
		dict["act"],
	)


class List:
	var _items: Array[Self]
	
	func _init(items: Array[Self]):
		_items = items
	
	func by_key(key: String) -> Self:
		for item in _items:
			if item.key == key:
				return item
		assert(false, "Item was not found")
		return null
	
	func sub_list(keys: PackedStringArray) -> List:
		var items: Array[Self]
		for item in _items:
			if keys.has(item.key):
				items.append(item)
		return List.new(items)
	
	func all() -> Array[Self]:
		return _items


class Self:
	signal disabled(val: bool)
	
	var key: String:
		get: return _key
		set(_v): utils.prop_is_readonly()
	
	var label: String:
		get: return _label
		set(_v): utils.prop_is_readonly()
	
	var icon: Icon:
		get: return _icon
		set(_v): utils.prop_is_readonly()
	
	var _key: String
	var _label: String
	var _icon: Icon
	var _act: Callable
	var _is_disabled: bool = false
	
	func _init(key: String, label: String, icon: Icon, act: Callable):
		_key = key
		_label = label
		_icon = icon
		_act = act
	
	func act():
		assert(not _is_disabled, "Unable to run the disabled action")
		_act.call()
	
	func disable(val: bool):
		_is_disabled = val
		disabled.emit(val)
	
	func to_btn() -> ButtonControl:
		return ButtonControl.new(self)


class Icon:
	func texture() -> Texture2D:
		return utils.not_implemeted()


class IconTheme extends Icon:
	var _control: Control
	var _name: StringName
	var _theme_type: StringName
	
	func _init(control: Control, name: StringName, theme_type: StringName):
		_control = control
		_name = name
		_theme_type = theme_type
	
	func texture() -> Texture2D:
		return _control.get_theme_icon(_name, _theme_type)


class ButtonControl extends Button:
	var _action: Action.Self
	
	func _init(action: Action.Self):
		_action = action
		text = _action.label
		pressed.connect(_action.act)
		action.disabled.connect(func(v): disabled = v)
	
	func _notification(what):
		if NOTIFICATION_THEME_CHANGED == what:
			icon = _action.icon.texture()

	func show_text(val) -> ButtonControl:
		if val:
			text = _action.label
			icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			text = ""
			icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			size_flags_horizontal = Control.SIZE_FILL
		return self
	
	func make_flat(val) -> ButtonControl:
		flat = val
		return self
	
	func horizontal_flags(flags) -> ButtonControl:
		size_flags_horizontal = flags
		return self
