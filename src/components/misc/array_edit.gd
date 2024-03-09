class_name ArrayEdit
extends VBoxContainer


@export var _add_item_text: String

var _items_vbox: VBoxContainer = VBoxContainer.new()
var _add_item_btn = Button.new()


func _init():
	_add_item_btn.pressed.connect(add_item)
	add_child(_items_vbox)
	add_child(_add_item_btn)


func _ready():
	_add_item_btn.text = tr(_add_item_text)
	_items_vbox.child_order_changed.connect(_update_items_move_enabled)


func override_array(array: PackedStringArray):
	for item in _items_vbox.get_children():
		item.hide()
		item.queue_free()
	
	for el in array:
		add_item(el)


func add_item(value=""):
	var item = Item.new(value)
	item.move_requested.connect(func(dir: int):
		_items_vbox.move_child(item, item.get_index() + dir)
	)
	_items_vbox.add_child(item)


func get_array() -> PackedStringArray:
	var result: PackedStringArray = []
	for item in _items_vbox.get_children():
		var val = item.get_value()
		if not val.is_empty():
			result.append(val)
	return result


func _update_items_move_enabled():
	for item: Item in _items_vbox.get_children():
		item.move_up_enable(item.get_index() != 0)
		item.move_down_enable(item.get_index() < _items_vbox.get_child_count() - 1)


func _notification(what):
	if what == NOTIFICATION_THEME_CHANGED:
		_add_item_btn.icon = get_theme_icon("Add", "EditorIcons")


class Item extends HBoxContainer:
	signal move_requested(dir: int)
	
	var _line_edit: LineEdit = LineEdit.new()
	var _free_btn: Button = Button.new()
	var _move_up_btn: Button = Button.new()
	var _move_down_btn: Button = Button.new()
	
	func _init(value):
		_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_line_edit.text = value
		add_child(_line_edit)
		add_child(_move_up_btn)
		add_child(_move_down_btn)
		add_child(_free_btn)
	
	func _ready():
		_free_btn.pressed.connect(queue_free)
		_move_up_btn.pressed.connect(_emit_move_requested(-1))
		_move_down_btn.pressed.connect(_emit_move_requested(1))
	
	func move_up_enable(enabled):
		_move_up_btn.disabled = not enabled

	func move_down_enable(enabled):
		_move_down_btn.disabled = not enabled

	func get_value():
		return _line_edit.text.strip_edges()
	
	func _emit_move_requested(dir: int):
		return func(): move_requested.emit(dir)
	
	func _notification(what):
		if what == NOTIFICATION_THEME_CHANGED:
			_free_btn.icon = get_theme_icon("Remove", "EditorIcons")
			_move_up_btn.icon = get_theme_icon("MoveUp", "EditorIcons")
			_move_down_btn.icon = get_theme_icon("MoveDown", "EditorIcons")
