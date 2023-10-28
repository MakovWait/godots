class_name AssetListItemView
extends HBoxContainer

signal title_pressed(item: AssetLib.Item)
signal category_pressed(item: AssetLib.Item)
signal author_pressed(item: AssetLib.Item)

@onready var _title = %Title
@onready var _category = %Category
@onready var _author = %Author
@onready var _cost = %Cost
@onready var _icon = %Icon


func _init():
	custom_minimum_size = Vector2i(400, 100) * Config.EDSCALE
	add_theme_constant_override("separation", 15 * Config.EDSCALE)


func _ready():
	_icon.texture = get_theme_icon("ProjectIconLoading", "EditorIcons")
	_category.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_author.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_cost.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))


func init(item: AssetLib.Item, images: RemoteImageSrc.I):
	_title.text = item.title
	_category.text = item.category
	_author.text = item.author
	_cost.text = item.cost
	
	_title.pressed.connect(func():
		title_pressed.emit(item)
	)
	_category.pressed.connect(func():
		category_pressed.emit(item)
	)
	_author.pressed.connect(func():
		author_pressed.emit(item)
	)
	
	images.async_load_img(item.icon_url, func(img): _icon.texture = img)


func get_icon_texture() -> Texture2D:
	return _icon.texture
