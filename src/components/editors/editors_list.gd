extends VBoxContainer

@export var _editor_item_scene: PackedScene

@onready var _items_container: VBoxContainer = %ItemsContainer


func _ready():
	theme_changed.connect(_update_theme)


func _update_theme():
	$ScrollContainer.set(
		"theme_override_styles/panel",
		get_theme_stylebox("panel", "EditorsListScrollContainer")
	)


func load_items(items):
	for item in items:
		var editor_control = _editor_item_scene.instantiate()
		_items_container.add_child(editor_control)
		editor_control.init(item)
