class_name AssetsContainer
extends GridContainer

signal title_pressed(item: AssetLib.Item)
signal category_pressed(item: AssetLib.Item)
signal author_pressed(item: AssetLib.Item)

@export var _list_item_scene: PackedScene
@export var _size_source: Control


func _ready():
	_size_source.resized.connect(func():
		_update_columns()
	)


func fill(items: Array[AssetLib.Item]):
	clear()
	for item in items:
		var item_view = _list_item_scene.instantiate() as AssetListItemView
		add_child(item_view)
		item_view.init(item)
		item_view.title_pressed.connect(func(i): title_pressed.emit(i))
		item_view.category_pressed.connect(func(i): category_pressed.emit(i))
		item_view.author_pressed.connect(func(i): author_pressed.emit(i))


func clear():
	for c in get_children():
		if c.has_method("hide"):
			c.hide()
		c.queue_free()


func _update_columns():
	var new_columns = _size_source.size.x / (450 * Config.EDSCALE)
	new_columns = max(1, new_columns)
#	prints(size.x, new_columns, (size.x / new_columns) - (100 * Config.EDSCALE))
	if new_columns != columns:
		columns = new_columns
#	for c in _assets_container.get_children():
#		c.custom_minimum_size = Vector2i(
#			(size.x / new_columns) - (100 * Config.EDSCALE),
#			c.custom_minimum_size.y
#		)
