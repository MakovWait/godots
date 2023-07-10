class_name VBoxList
extends VBoxContainer

signal item_selected(item)


@export var _item_scene: PackedScene
@onready var _items_container: VBoxContainer = %ItemsContainer


func _ready():
	_update_theme()
	theme_changed.connect(_update_theme)


func _update_theme():
	$SearchBox.right_icon = get_theme_icon("Search", "EditorIcons")
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


func _post_add(item_data, item_control):
	pass


func _on_item_clicked(item):
	for child in _items_container.get_children():
		if child.has_method("deselect"):
			child.deselect()
	item.select()
	item_selected.emit(item)


func _on_search_box_text_changed(new_text: String) -> void:
	for item in _items_container.get_children():
		if item.has_method("apply_filter"):
			var should_be_visible = item.apply_filter(func(data): 
				if len(new_text) == 0: return true
				return new_text.is_subsequence_ofn(data['name'])
			)
			item.visible = should_be_visible
