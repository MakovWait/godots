class_name VBoxList
extends VBoxContainer

signal item_selected(item)


@export var _item_scene: PackedScene

@onready var _items_container: VBoxContainer = %ItemsContainer
@onready var _sort_option_button: OptionButton = %SortOptionButton


func _ready():
	_update_theme()
	theme_changed.connect(_update_theme)
	_fill_sort_options(_sort_option_button)
	_sort_option_button.item_selected.connect(func(_arg):
		sort_items()
	)


func _update_theme():
	%SearchBox.right_icon = get_theme_icon("Search", "EditorIcons")
	$ScrollContainer.add_theme_stylebox_override(
		"panel",
		get_theme_stylebox("search_panel", "ProjectManager")
	)


func refresh(data):
	for child in _items_container.get_children():
		child.queue_free()
	for item_data in data:
		add(item_data)


func add(item_data):
	var item_control = _item_scene.instantiate()
	_items_container.add_child(item_control)
	item_control.init(item_data)
	item_control.clicked.connect(
		_on_item_clicked.bind(item_control)
	)
	if item_control.has_signal("tag_clicked"):
		item_control.tag_clicked.connect(
			func(tag): 
				var search_box = %SearchBox
				search_box.text = "tag:%s" % tag
				search_box.text_changed.emit(search_box.text)
				search_box.grab_focus()
		)
	_post_add(item_data, item_control)


func sort_items():
	var sort_data = _items_container.get_children().map(
		func(x): return x.get_sort_data()
	)
	sort_data.sort_custom(self._item_comparator)
	for i in range(len(sort_data)):
		var sorted_item = sort_data[i]
		_items_container.move_child(
			sorted_item.ref,
			i
		)


func _item_comparator(a, b):
	pass


func _fill_sort_options(btn: OptionButton):
	pass


func _post_add(item_data, item_control):
	pass


func _on_item_clicked(item):
	for child in _items_container.get_children():
		if child.has_method("deselect"):
			child.deselect()
	item.select()
	item_selected.emit(item)


func _on_search_box_text_changed(new_text: String) -> void:
	var search_tag = ""
	var search_term = ""
	for part in new_text.split(" "):
		if part.begins_with("tag:"):
			var tag_parts = part.split(":")
			if len(tag_parts) > 1:
				search_tag = part.split(":")[1]
		else:
			search_term += part

	for item in _items_container.get_children():
		if item.has_method("apply_filter"):
			var should_be_visible = item.apply_filter(func(data): 
				var search_path = data['path']
				if not search_term.contains('/'):
					search_path = search_path.get_file()
				var check_path = search_path.findn(search_term) != -1
				var check_name = data['name'].findn(search_term) != -1
				var check_term = search_term.is_empty() or check_path or check_name
				if not search_tag.is_empty():
					return check_term and _has_tag(data, search_tag)
				else:
					return check_term
			)
			item.visible = should_be_visible


func _has_tag(tags_source, tag):
	return Array(tags_source.tags).find(tag) > -1
