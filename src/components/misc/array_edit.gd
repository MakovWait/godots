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


func add_item():
	_items_vbox.add_child(Item.new())


func get_array() -> PackedStringArray:
	var result: PackedStringArray = []
	for item in _items_vbox.get_children():
		var val = item.get_value()
		if not val.is_empty():
			result.append(val)
	return result


func _notification(what):
	if what == NOTIFICATION_THEME_CHANGED:
		_add_item_btn.icon = get_theme_icon("Add", "EditorIcons")


class Item extends HBoxContainer:
	var _line_edit: LineEdit = LineEdit.new()
	var _free_btn: Button = Button.new()
	
	func _init():
		_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(_line_edit)
		add_child(_free_btn)
	
	func _ready():
		_free_btn.pressed.connect(queue_free)
	
	func get_value():
		return _line_edit.text.strip_edges()
	
	func _notification(what):
		if what == NOTIFICATION_THEME_CHANGED:
			_free_btn.icon = get_theme_icon("Remove", "EditorIcons")
