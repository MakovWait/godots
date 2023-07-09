extends VBoxContainer

signal editor_item_selected(actions_source)
signal editor_item_removed(editor_data)


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


func refresh(items):
	for child in _items_container.get_children():
		child.queue_free()
	for item in items:
		add(item)


func add(item):
	var editor_control = _editor_item_scene.instantiate()
	_items_container.add_child(editor_control)
	editor_control.init(item)
	editor_control.clicked.connect(
		_on_editor_item_clicked.bind(editor_control)
	)
	editor_control.removed.connect(
		_on_editor_item_removed.bind(editor_control, item)
	)


func _on_editor_item_removed(editor_control, editor_data):
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.ok_button_text = "Remove"
	confirmation_dialog.dialog_text = "Are you sure to remove the editor from the file system?"
	confirmation_dialog.visibility_changed.connect(func(): 
		if not confirmation_dialog.visible:
			confirmation_dialog.queue_free()
	)
	confirmation_dialog.confirmed.connect(func():
		editor_control.queue_free()
		editor_item_removed.emit(editor_data)
	)
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()


func _on_editor_item_clicked(editor_item):
	for child in _items_container.get_children():
		if child.has_method("deselect"):
			child.deselect()
	editor_item.select()
	editor_item_selected.emit(editor_item)
