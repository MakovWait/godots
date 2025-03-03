class_name TabActions


class Settings:
	signal changed
	
	var _visible_keys: ConfigFileValue
	var _is_flat: ConfigFileValue
	var _show_text: ConfigFileValue
	var _default_visible_keys: Array[String]
	
	func _init(cache_section: String, default_visible_keys: Array[String]) -> void:
		_visible_keys = Cache.smart_value(cache_section, 'visible-keys', true)
		_is_flat = Cache.smart_value(cache_section, 'is-flat', true)
		_show_text = Cache.smart_value(cache_section, 'show-text', true)
		_default_visible_keys = default_visible_keys
	
	func add_to_popup(idx: int, popup: PopupMenu) -> void:
		popup.add_check_item(tr("Flat"))
		popup.set_item_metadata(idx, {
			'on_pressed': func() -> void:
				popup.toggle_item_checked(idx)
				set_flat(popup.is_item_checked(idx))
		})
		popup.set_item_checked(idx, is_flat())
		
		idx = idx + 1
		popup.add_check_item(tr("Show Text"))
		popup.set_item_metadata(idx, {
			'on_pressed': func() -> void:
				popup.toggle_item_checked(idx)
				set_show_text(popup.is_item_checked(idx))
		})
		popup.set_item_checked(idx, is_show_text())
	
	func is_flat() -> bool:
		return _is_flat.ret(false)
	
	func set_flat(value: bool) -> void:
		_is_flat.put(value)
		changed.emit()
	
	func is_show_text() -> bool:
		return _show_text.ret(true)
	
	func set_show_text(value: bool) -> void:
		_show_text.put(value)
		changed.emit()
	
	func is_key_visible(key: String) -> bool:
		return (_visible_keys.ret(_default_visible_keys) as Array).has(key)
	
	func set_key_visible(key: String, is_visible: bool) -> void:
		var keys := _visible_keys.ret(_default_visible_keys) as Array
		if is_visible:
			keys.append(key)
		else:
			keys.erase(key)
		_visible_keys.put(keys)
		changed.emit()


class Menu extends MenuButton:
	var _views: Views
	var _settings: Settings
	var _settings_popup: PopupMenu
	
	func _init(actions: Array[Action.Self], settings: Settings) -> void:
		_views = Views.new(actions, settings)
		_settings = settings
		ready.connect(_setup_popup)
	
	func _setup_popup() -> void:
		var popup := get_popup()
		popup.hide_on_checkable_item_selection = false
		popup.id_pressed.connect(func(id: int) -> void:
			((popup.get_item_metadata(
				popup.get_item_index(id)
			) as Dictionary).get('on_pressed', utils.empty_func) as Callable).call()
		)
		
		_settings_popup = PopupMenu.new()
		_settings_popup.name = "Settings"
		_settings_popup.hide_on_checkable_item_selection = false
		_settings_popup.id_pressed.connect(func(id: int) -> void:
			((_settings_popup.get_item_metadata(
				_settings_popup.get_item_index(id)
			) as Dictionary).get('on_pressed', utils.empty_func) as Callable).call()
		)
		popup.add_child(_settings_popup)
		
		for view in _views.all():
			view.add_to_popup(popup.item_count, popup)
		
		popup.add_separator()
		popup.add_submenu_item("Config", "Settings")
		popup.set_item_icon(popup.item_count - 1, popup.get_theme_icon("Tools", "EditorIcons"))
		
		_settings_popup.add_separator(tr("Visibility"))
		for view in _views.all():
			view.add_to_show_section(_settings_popup.item_count, _settings_popup)
		_settings_popup.add_separator(tr("Appearance"))
		_settings.add_to_popup(_settings_popup.item_count, _settings_popup)
	
	func add_controls_to_node(control: Control) -> void:
		for view in _views.all():
			view.add_to_node(control)

	class View:
		var _o: Action.Self
		var _control: Action.ButtonControl
		var _settings: Settings

		func _init(action: Action.Self, settings: Settings) -> void:
			_settings = settings
			_o = action
			_control = action.to_btn()
			settings.changed.connect(_sync_settings)
		
		func add_to_popup(idx: int, popup: PopupMenu) -> void:
			popup.add_item(_o.label, idx)
			popup.set_item_icon(idx, _o.icon.texture())
			popup.set_item_metadata(idx, {'on_pressed': _o.act})
		
		func add_to_show_section(idx: int, popup: PopupMenu) -> void:
			popup.add_check_item(_o.label)
			popup.set_item_icon(idx, _o.icon.texture())
			popup.set_item_metadata(idx, {'on_pressed': func() -> void:
				popup.toggle_item_checked(idx)
				set_visible(popup.is_item_checked(idx))
			})
			popup.set_item_checked(idx, is_visible())
		
		func is_visible() -> bool:
			return _settings.is_key_visible(_o.key)
		
		func set_visible(val: bool) -> void:
			_settings.set_key_visible(_o.key, val)
		
		func add_to_node(node: Control) -> void:
			node.add_child(_control)
			_sync_settings()
		
		func _sync_settings() -> void:
			_control.visible = is_visible()
			_control.flat = _settings.is_flat()
			_control.show_text(_settings.is_show_text())

	class Views:
		var _items: Array[View]
		
		func _init(actions: Array[Action.Self], settings: Settings) -> void:
			for action in actions:
				add(action, settings)
		
		func add(action: Action.Self, settings: Settings) -> View:
			var view := View.new(action, settings)
			_items.append(view)
			return view
		
		func all() -> Array[View]:
			return _items
