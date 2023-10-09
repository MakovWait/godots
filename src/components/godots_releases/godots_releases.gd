extends HBoxContainer

@onready var _godots_releases_list = $GodotsReleasesList as VBoxList
@onready var _sidebar = $ScrollContainer/ActionsSidebar
@onready var _refresh_button = %RefreshButton

var _releases: GodotsReleases.I
var _godots_downloads: GodotsDownloads.I
var _godots_install: GodotsInstall.I
var _data_loaded = false
var _fetching = false


func init(
	releases: GodotsReleases.I,
	godots_downloads: GodotsDownloads.I,
	godots_install: GodotsInstall.I
):
	self._releases = releases
	self._godots_install = godots_install
	self._godots_downloads = godots_downloads
	
	if visible:
		_async_refetch_data()


func _ready():
	_godots_releases_list.set_search_box_text("tag:newest")
	_refresh_button.pressed.connect(func():
		_async_refetch_data()
	)


func _async_refetch_data():
	if _fetching or _releases == null:
		return
	_fetching = true
	_refresh_button.disabled = true
	
	_async_refetch_data_body()
	
	_data_loaded = true
	_fetching = false
	_refresh_button.disabled = false


func _async_refetch_data_body():
	await _releases.async_load()
	_godots_releases_list.refresh(_releases.all())


func _on_godots_releases_list_item_selected(item):
	_sidebar.refresh_actions(item.get_actions())


func _on_godots_releases_list_download_and_install_requested(url):
	_godots_downloads.download(
		url,
		func(abs_zip_path): _godots_install.install(abs_zip_path)
	)


func _on_visibility_changed():
	if visible and not _data_loaded:
		_async_refetch_data()
