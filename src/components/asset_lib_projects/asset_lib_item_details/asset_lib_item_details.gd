extends ConfirmationDialog

signal download_requested(download_url, icon)

@onready var _asset_list_item = %AssetListItem as AssetListItemView
@onready var _description_label = %DescriptionLabel
@onready var _preview = %Preview
@onready var _preview_bg = %PreviewBg
@onready var _previews_container = %PreviewsContainer

var _item_id
var _asset_lib: AssetLib.I


func init(item_id, asset_lib: AssetLib.I):
	_item_id = item_id
	_asset_lib = asset_lib


func _ready():
#	_preview.texture = get_theme_icon("ThumbnailWait", "EditorIcons")
	_description_label.add_theme_constant_override("line_separation", round(5 * Config.EDSCALE))

	_preview.custom_minimum_size = Vector2(640, 345) * Config.EDSCALE
	_preview_bg.custom_minimum_size = Vector2(640, 101) * Config.EDSCALE
	
	var item = await _asset_lib.async_fetch_one(_item_id)
	_configure(item)


func _configure(item: AssetLib.Item):
	confirmed.connect(func():
		download_requested.emit(item.download_url, null)
	)
	_asset_list_item.init(item)
	_description_label.configure(item)
	title = item.title
	for preview in item.previews:
		add_preview(preview)


func add_preview(item: AssetLib.ItemPreview):
	var btn = Button.new()
	btn.icon = get_theme_icon("ThumbnailWait", "EditorIcons")
	btn.toggle_mode = true
	_previews_container.add_child(btn)
	if not item.is_video:
		pass


func _notification(what):
	if what == NOTIFICATION_THEME_CHANGED:
		%PreviewBg.add_theme_stylebox_override("panel", get_theme_stylebox("normal", "TextEdit"))
