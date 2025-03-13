class_name AssetLibItemDetailsDialog
extends ConfirmationDialog

signal download_requested(item: AssetLib.Item, icon: Texture2D)

@onready var _asset_list_item := %AssetListItem as AssetListItemView
@onready var _description_label := %DescriptionLabel as AssetLibDetailsDescriptionLabel
@onready var _preview := %Preview as TextureRect
@onready var _preview_bg := %PreviewBg as PanelContainer
@onready var _previews_container := %PreviewsContainer as HBoxContainer

var _item_id: String
var _asset_lib: AssetLib.I
var _images_src: RemoteImageSrc.I


func init(item_id: String, asset_lib: AssetLib.I, images: RemoteImageSrc.I) -> void:
	_item_id = item_id
	_asset_lib = asset_lib
	_images_src = images


func _ready() -> void:
#	_preview.texture = get_theme_icon("ThumbnailWait", "EditorIcons")
	_description_label.add_theme_constant_override("line_separation", roundi(5 * Config.EDSCALE))

	_preview.custom_minimum_size = Vector2(640, 345) * Config.EDSCALE
	_preview_bg.custom_minimum_size = Vector2(640, 101) * Config.EDSCALE

	@warning_ignore("redundant_await")
	var item := await _asset_lib.async_fetch_one(_item_id)
	_configure(item)


func _configure(item: AssetLib.Item) -> void:
	confirmed.connect(func() -> void:
		download_requested.emit(item, _asset_list_item.get_icon_texture())
	)
	_asset_list_item.init(item, _images_src)
	_description_label.configure(item)
	title = item.title
	var first_preview_selected := false
	for preview in item.previews:
		@warning_ignore("redundant_await")
		var btn := await add_preview(preview)
		if not first_preview_selected and not preview.is_video:
			first_preview_selected = true
			_handle_btn_pressed.bind(preview, btn).call_deferred()


func add_preview(item: AssetLib.ItemPreview) -> Button:
	var btn := Button.new()
	btn.icon = get_theme_icon("ThumbnailWait", "EditorIcons")
	btn.toggle_mode = true
	btn.pressed.connect(_handle_btn_pressed.bind(item, btn))
	_previews_container.add_child(btn)
	@warning_ignore("redundant_await")
	await _images_src.async_load_img(item.thumbnail, func(tex: Texture2D) -> void:
		if not item.is_video:
			if tex is ImageTexture:
				utils.fit_height(85 * Config.EDSCALE, tex.get_size(), func(new_size: Vector2i) -> void:
					(tex as ImageTexture).set_size_override(new_size)
				)
			btn.icon = tex
		else:
			var overlay := get_theme_icon("PlayOverlay", "EditorIcons").get_image()
			var tex_image: Image = tex.get_image()
			if tex_image == null:
				tex_image = get_theme_icon("FileBrokenBigThumb", "EditorIcons").get_image()
			utils.fit_height(85 * Config.EDSCALE, tex_image.get_size(), func(new_size: Vector2i) -> void:
				tex_image.resize(new_size.x, new_size.y, Image.INTERPOLATE_LANCZOS)
			)
			var thumbnail := tex_image.duplicate() as Image
			var overlay_pos := Vector2i(
				int((thumbnail.get_width() - overlay.get_width()) / 2.0),
				int((thumbnail.get_height() - overlay.get_height()) / 2.0)
			)
			thumbnail.convert(Image.FORMAT_RGBA8)
			thumbnail.blend_rect(overlay, overlay.get_used_rect(), overlay_pos)
			btn.icon = ImageTexture.create_from_image(thumbnail)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	)
	return btn


func _handle_btn_pressed(item: AssetLib.ItemPreview, btn: Button) -> void:
	for child in _previews_container.get_children():
		child.set("button_pressed", false)
	btn.button_pressed = true
	if item.is_video:
		OS.shell_open(item.link)
	else:
		_images_src.async_load_img(item.link, func(tex: Texture2D) -> void:
			if tex is ImageTexture:
				utils.fit_height(397 * Config.EDSCALE, tex.get_size(), func(new_size: Vector2i) -> void:
					(tex as ImageTexture).set_size_override(new_size)
				)
			_preview.texture = tex
		)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		(%PreviewBg as Control).add_theme_stylebox_override("panel", get_theme_stylebox("normal", "TextEdit"))
