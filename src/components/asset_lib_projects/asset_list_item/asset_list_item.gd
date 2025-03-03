class_name AssetListItemView
extends HBoxContainer

const DEFAULT_MIN_SIZE_X = 390

signal title_pressed(item: AssetLib.Item)
signal category_pressed(item: AssetLib.Item)
signal author_pressed(item: AssetLib.Item)

@onready var _title := %Title as LinkButton
@onready var _category := %Category as LinkButton
@onready var _author := %Author as LinkButton
@onready var _cost := %Cost as Label
@onready var _icon := %Icon as TextureRect


var _original_title_text: String


func _init() -> void:
	custom_minimum_size = Vector2i(DEFAULT_MIN_SIZE_X, 100) * Config.EDSCALE
	add_theme_constant_override("separation", 15 * Config.EDSCALE)


func _ready() -> void:
	_icon.texture = get_theme_icon("ProjectIconLoading", "EditorIcons")
	_category.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_author.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_cost.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))


func init(item: AssetLib.Item, images: RemoteImageSrc.I) -> void:
	_title.text = item.title
	_category.text = item.category
	_author.text = item.author
	_cost.text = item.cost
	
	_original_title_text = item.title
	
	_title.pressed.connect(func() -> void:
		title_pressed.emit(item)
	)
	_category.pressed.connect(func() -> void:
		category_pressed.emit(item)
	)
	_author.pressed.connect(func() -> void:
		author_pressed.emit(item)
	)

	images.async_load_img(item.icon_url, func(tex: Texture2D) -> void:
		if tex is ImageTexture:
			(tex as ImageTexture).set_size_override(Vector2i(64, 64) * Config.EDSCALE)
		_icon.texture = tex
	)
	clamp_width(DEFAULT_MIN_SIZE_X)


func get_icon_texture() -> Texture2D:
	return _icon.texture


func clamp_width(max_width: int) -> void:
	var _title_font: Font = _title.get_theme_font("font")
	var text_pixel_width := _title_font.get_string_size(_original_title_text).x * Config.EDSCALE

	var full_text := _original_title_text
	_title.tooltip_text = full_text

	if text_pixel_width > max_width:
		# Truncate title text to within the current column width.
		var max_length := max_width / (text_pixel_width / full_text.length())
		var truncated_text := full_text.left(max_length - 3) + "..."
		_title.text = truncated_text
