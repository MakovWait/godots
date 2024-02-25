class_name ProjectItemActions


class Settings:
	signal changed
	
	var _visible_keys: ConfigFileValue
	var _show_tags: ConfigFileValue
	var _show_features: ConfigFileValue
	var _default_visible_keys: Array[String]
	
	func _init(cache_section: String, default_visible_keys: Array[String]):
		_visible_keys = Cache.smart_value(cache_section, 'visible-keys', true)
		_show_tags = Cache.smart_value(cache_section, 'show-tags', true) 
		_show_features = Cache.smart_value(cache_section, 'show-features', true) 
		_default_visible_keys = default_visible_keys
	
	func add_to_popup(idx: int, popup: PopupMenu, on_about_to_popup: Array[Callable]):
		popup.add_check_item(tr("Show Tags"))
		popup.set_item_metadata(idx, {
			'on_pressed': func():
				popup.toggle_item_checked(idx)
				set_show_tags(popup.is_item_checked(idx))
		})
		on_about_to_popup.append(func():
			popup.set_item_checked(idx, is_show_tags())
		)

		idx = idx + 1
		popup.add_check_item(tr("Show Features"))
		popup.set_item_metadata(idx, {
			'on_pressed': func():
				popup.toggle_item_checked(idx)
				set_show_features(popup.is_item_checked(idx))
		})
		on_about_to_popup.append(func():
			popup.set_item_checked(idx, is_show_features())
		)


	func is_flat() -> bool:
		return true
	
	#func set_flat(value: bool):
		#_is_flat.put(value)
		#changed.emit()
	
	func is_show_text() -> bool:
		return false

	#func set_show_text(value: bool):
		#_show_text.put(value)
		#changed.emit()

	func is_show_features() -> bool:
		return _show_features.ret(true)

	func set_show_features(value: bool):
		_show_features.put(value)
		changed.emit()

	func is_show_tags() -> bool:
		return _show_tags.ret(true)

	func set_show_tags(value: bool):
		_show_tags.put(value)
		changed.emit()

	func is_key_visible(key: String) -> bool:
		return _visible_keys.ret(_default_visible_keys).has(key)

	func set_key_visible(key: String, is_visible: bool):
		var keys = _visible_keys.ret(_default_visible_keys)
		if is_visible:
			keys.append(key)
		else:
			keys.erase(key)
		_visible_keys.put(keys)
		changed.emit()


class Menu extends MenuButton:
	var _views: Views
	var _settings: Settings
	var _on_about_to_popup: Array[Callable]
	
	func _init(actions: Array[Action.Self], settings: Settings):
		_views = Views.new(actions, settings)
		_settings = settings
		_setup_popup()
	
	func _setup_popup():
		var popup := get_popup()
		about_to_popup.connect(func():
			for callback in _on_about_to_popup:
				callback.call()
		)
		popup.hide_on_checkable_item_selection = false
		popup.id_pressed.connect(func(id):
			get_popup().get_item_metadata(
				get_popup().get_item_index(id)
			).get('on_pressed', utils.empty_func).call()
		)
		for view in _views.all():
			view.add_to_popup(popup.item_count, popup)
		popup.add_separator(tr("Visible"))
		for view in _views.all():
			view.add_to_show_section(popup.item_count, popup)
		popup.add_separator(tr("Appearance"))
		_settings.add_to_popup(popup.item_count, popup, _on_about_to_popup)
	
	func add_controls_to_node(control: Control):
		for view in _views.all():
			view.add_to_node(control)

	class View:
		var _o: Action.Self
		var _control: Action.ButtonControl
		var _settings: Settings

		func _init(action: Action.Self, settings: Settings):
			_settings = settings
			_o = action
			_control = action.to_btn()
			#_control.mouse_filter = Control.MOUSE_FILTER_PASS
			settings.changed.connect(_sync_settings)
		
		func add_to_popup(idx: int, popup: PopupMenu):
			popup.add_item(_o.label, idx)
			popup.set_item_icon(idx, _o.icon.texture())
			popup.set_item_metadata(idx, {'on_pressed': _o.act})
		
		func add_to_show_section(idx: int, popup: PopupMenu):
			popup.add_check_item(_o.label)
			popup.set_item_icon(idx, _o.icon.texture())
			popup.set_item_metadata(idx, {'on_pressed': func():
				popup.toggle_item_checked(idx)
				set_visible(popup.is_item_checked(idx))
			})
			popup.set_item_checked(idx, is_visible())
		
		func is_visible():
			return _settings.is_key_visible(_o.key)
		
		func set_visible(val):
			_settings.set_key_visible(_o.key, val)
		
		func add_to_node(node: Control):
			node.add_child(_control)
			_sync_settings()
		
		func _sync_settings():
			_control.visible = is_visible()
			_control.flat = _settings.is_flat()
			_control.show_text(_settings.is_show_text())

	class Views:
		var _items: Array[View]
		
		func _init(actions: Array[Action.Self], settings: Settings):
			for action in actions:
				add(action, settings)
		
		func add(action: Action.Self, settings: Settings) -> View:
			var view = View.new(action, settings)
			_items.append(view)
			return view
		
		func all() -> Array[View]:
			return _items
