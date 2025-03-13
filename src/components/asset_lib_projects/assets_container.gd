class_name AssetsContainer
extends GridContainer

signal title_pressed(item: AssetLib.Item)
signal category_pressed(item: AssetLib.Item)
signal author_pressed(item: AssetLib.Item)

@export var _list_item_scene: PackedScene
@export var _size_source: Control


var _images_src: RemoteImageSrc.I


func init(images_src: RemoteImageSrc.I) -> void:
	_images_src = images_src


func _ready() -> void:
	_size_source.resized.connect(func() -> void:
		_update_columns()
	)


func fill(items: Array[AssetLib.Item]) -> void:
	clear()
	for item in items:
		var item_view := _list_item_scene.instantiate() as AssetListItemView
		add_child(item_view)
		item_view.init(item, _images_src)
		item_view.title_pressed.connect(func(i: AssetLib.Item) -> void: title_pressed.emit(i))
		item_view.category_pressed.connect(func(i: AssetLib.Item) -> void: category_pressed.emit(i))
		item_view.author_pressed.connect(func(i: AssetLib.Item) -> void: author_pressed.emit(i))


func clear() -> void:
	for c in get_children():
		if c.has_method("hide"):
			c.call("hide")
		c.queue_free()


func _update_columns() -> void:
	var new_columns := _size_source.size.x / (400 * Config.EDSCALE)
	new_columns = max(1, new_columns)
#	prints(size.x, new_columns, (size.x / new_columns) - (100 * Config.EDSCALE))
	if new_columns != columns:
		columns = int(new_columns)
#	for c in get_children():
#		if c.has_method('clamp_width'):
#			c.clamp_width((size.x / new_columns) - (100 * Config.EDSCALE))
