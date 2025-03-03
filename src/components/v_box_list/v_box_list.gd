class_name VBoxList
extends VBoxContainer

signal item_selected(item: Variant)

@export var _item_scene: PackedScene

@export_group("Cache")
@export var _search_cache_is_enabled: bool
@export var _cached_search_key: String

@onready var _items_container: VBoxContainer = %ItemsContainer
@onready var _sort_option_button: OptionButton = %SortOptionButton
@onready var _search_box := %SearchBox as LineEdit
@onready var _cached_search_value := Cache.smart_value(self, _cached_search_key, true)


func _ready() -> void:
	_update_theme()
	theme_changed.connect(_update_theme)
	_fill_sort_options(_sort_option_button)
	_sort_option_button.item_selected.connect(func(_arg: int) -> void:
		sort_items()
	)
	restore_last_search_value_from_cache()


func _update_theme() -> void:
	_search_box.right_icon = get_theme_icon("Search", "EditorIcons")
	(%ScrollContainer as ScrollContainer).add_theme_stylebox_override(
		"panel",
		get_theme_stylebox("search_panel", "ProjectManager")
	)


func set_search_box_text(text: String) -> void:
	_search_box.text = text
	_cache_search_value(_search_box.text)
	_update_filters()


func refresh(data: Array) -> void:
	for child in _items_container.get_children():
		child.queue_free()
	for item_data: Object in data:
		add(item_data)
	_update_filters()


func add(item_data: Object) -> void:
	var item_control: Control = _item_scene.instantiate()
	_items_container.add_child(item_control)
	item_control.call("init", item_data)
	item_control.connect("clicked", _select_item.bind(item_control))
	item_control.connect("right_clicked", _select_item.bind(item_control))
	if item_control.has_signal("tag_clicked"):
		item_control.connect("tag_clicked", 
			func(tag: String) -> void: 
				set_search_box_text("tag:%s" % tag)
				_search_box.grab_focus()
		)
	_post_add(item_data, item_control)


func sort_items() -> void:
	var sort_data := _items_container.get_children().map(
		func(x: Object) -> Dictionary: return x.call("get_sort_data") as Dictionary
	)
	sort_data.sort_custom(self._item_comparator)
	for i in range(len(sort_data)):
		var sorted_item := sort_data[i] as Dictionary
		_items_container.move_child(
			sorted_item.ref as Control,
			i
		)


func _item_comparator(a: Dictionary, b: Dictionary) -> bool:
	return utils.not_implemeted()


func _fill_sort_options(btn: OptionButton) -> void:
	pass


func _post_add(item_data: Object, item_control: Control) -> void:
	pass


func _select_item(item: Object) -> void:
	for child in _items_container.get_children():
		if child.has_method("deselect"):
			child.call("deselect")
	item.call("select")
	item_selected.emit(item)


func _on_search_box_text_changed(_new_text: String) -> void:
	_cache_search_value(_search_box.text)
	_update_filters()


func update_filters() -> void:
	_update_filters()


func _update_filters() -> void:
	var search_tag := ""
	var search_term := ""
	for part in _search_box.text.split(" "):
		if part.begins_with("tag:"):
			var tag_parts := part.split(":")
			if len(tag_parts) > 1:
				search_tag = part.split(":")[1]
		else:
			search_term += part

	for item: Control in _items_container.get_children():
		if item.has_method("apply_filter"):
			var should_be_visible: bool = item.call("apply_filter", func(data: Dictionary) -> bool:
				var search_path := data['path'] as String
				if not search_term.contains('/'):
					search_path = search_path.get_file()
				var check_path := search_path.findn(search_term) != -1
				var check_name := (data['name'] as String).findn(search_term) != -1
				var check_term := search_term.is_empty() or check_path or check_name
				if not search_tag.is_empty():
					return check_term and _has_tag(data, search_tag)
				else:
					return check_term
			)
			item.visible = should_be_visible


func _has_tag(tags_source: Dictionary, tag: String) -> bool:
	var tags := tags_source.tags as Array
	return tags.find(tag) > -1


func search_cache_is_enabled() -> bool:
	return _search_cache_is_enabled and not _cached_search_key.is_empty()


func restore_last_search_value_from_cache() -> void:
	if search_cache_is_enabled():
		set_search_box_text(_cached_search_value.ret("") as String)


func _cache_search_value(value: String) -> void:
	if search_cache_is_enabled():
		_cached_search_value.put(value)
