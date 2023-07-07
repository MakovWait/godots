extends VBoxContainer

signal editor_item_selected(editor_item)

@export var _editor_item_scene: PackedScene

@onready var _items_container: VBoxContainer = %ItemsContainer


func _ready():
	_update_theme()
	theme_changed.connect(_update_theme)


func _update_theme():
	$ScrollContainer.add_theme_stylebox_override(
		"panel",
		get_theme_stylebox("search_panel", "ProjectManager")
	)


func load_items(items):
	for item in items:
		var editor_control = _editor_item_scene.instantiate()
		_items_container.add_child(editor_control)
		editor_control.init(item)
		editor_control.clicked.connect(
			_on_editor_item_clicked.bind(editor_control)
		)


func _on_editor_item_clicked(editor_item):
	for child in _items_container.get_children():
		if child.has_method("deselect"):
			child.deselect()
	editor_item.select()
	editor_item_selected.emit(editor_item)
