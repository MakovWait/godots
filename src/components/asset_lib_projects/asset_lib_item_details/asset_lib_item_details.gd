extends ConfirmationDialog

signal download_requested(download_url, icon)

@onready var _asset_list_item = %AssetListItem as AssetListItemView
@onready var _description_label = %DescriptionLabel
@onready var _preview = %Preview
@onready var _preview_bg = %PreviewBg
@onready var _previews_container = %PreviewsContainer

var _item_id
var _asset_lib: AssetLib.I
var _images_src: RemoteImageSrc.I


func init(item_id, asset_lib: AssetLib.I, images: RemoteImageSrc.I):
	_item_id = item_id
	_asset_lib = asset_lib
	_images_src = images


func _ready():
#	_preview.texture = get_theme_icon("ThumbnailWait", "EditorIcons")
	_description_label.add_theme_constant_override("line_separation", round(5 * Config.EDSCALE))

	_preview.custom_minimum_size = Vector2(640, 345) * Config.EDSCALE
	_preview_bg.custom_minimum_size = Vector2(640, 101) * Config.EDSCALE
	
	var item = await _asset_lib.async_fetch_one(_item_id)
	_configure(item)


func _configure(item: AssetLib.Item):
	confirmed.connect(func():
		download_requested.emit(item.download_url, _asset_list_item.get_icon_texture())
	)
	_asset_list_item.init(item, _images_src)
	_description_label.configure(item)
	title = item.title
	var first_preview_selected = false
	for preview in item.previews:
		var btn = add_preview(preview)
		if not first_preview_selected and not preview.is_video:
			first_preview_selected = true
			_handle_btn_pressed.bind(preview, btn).call_deferred()


func add_preview(item: AssetLib.ItemPreview):
	var btn = Button.new()
	btn.icon = get_theme_icon("ThumbnailWait", "EditorIcons")
	btn.toggle_mode = true
	btn.pressed.connect(_handle_btn_pressed.bind(item, btn))
	_previews_container.add_child(btn)
	_images_src.async_load_img(item.thumbnail, func(img: Texture2D):
		if not item.is_video:
			btn.icon = img
		else:
			var overlay = get_theme_icon("PlayOverlay", "EditorIcons").get_image()
			var thumbnail = img.get_image().duplicate() as Image
			var overlay_pos = Vector2i(
				(thumbnail.get_width() - overlay.get_width()) / 2,
				(thumbnail.get_height() - overlay.get_height()) / 2
			)
			thumbnail.convert(Image.FORMAT_RGBA8)
			thumbnail.blend_rect(overlay, overlay.get_used_rect(), overlay_pos)
			btn.icon = ImageTexture.create_from_image(thumbnail)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	)
	return btn


func _handle_btn_pressed(item: AssetLib.ItemPreview, btn):
	for child in _previews_container.get_children():
		child.set("button_pressed", false)
	btn.button_pressed = true
	if item.is_video:
		OS.shell_open(item.link)
	else:
		_images_src.async_load_img(item.link, func(img: Texture2D):
			_preview.texture = img
		)


func _notification(what):
	if what == NOTIFICATION_THEME_CHANGED:
		%PreviewBg.add_theme_stylebox_override("panel", get_theme_stylebox("normal", "TextEdit"))
