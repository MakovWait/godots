class_name GodotsReleasesControl
extends HBoxContainer

@onready var _godots_releases_list := %GodotsReleasesList as VBoxList
@onready var _sidebar := %ActionsSidebar as ActionsSidebarControl
@onready var _refresh_button := %RefreshButton as Button
@onready var _star_git_hub := %StarGitHub as Button

var _releases: GodotsReleases.I
var _godots_downloads: GodotsDownloads.I
var _godots_install: GodotsInstall.I
var _data_loaded := false
var _fetching := false


func init(
	releases: GodotsReleases.I, godots_downloads: GodotsDownloads.I, godots_install: GodotsInstall.I
) -> void:
	self._releases = releases
	self._godots_install = godots_install
	self._godots_downloads = godots_downloads

	if visible:
		_async_refetch_data()


func _ready() -> void:
	_godots_releases_list.set_search_box_text("tag:newest")
	_refresh_button.pressed.connect(func() -> void: _async_refetch_data())

	_star_git_hub.icon = get_theme_icon("Favorites", "EditorIcons")
	_star_git_hub.pressed.connect(
		func() -> void: OS.shell_open("https://github.com/MakovWait/godots")
	)


func _async_refetch_data() -> void:
	if _fetching or _releases == null:
		return
	_fetching = true
	_refresh_button.disabled = true

	_async_refetch_data_body()

	_data_loaded = true
	_fetching = false
	_refresh_button.disabled = false


func _async_refetch_data_body() -> void:
	@warning_ignore("redundant_await")
	await _releases.async_load()
	_godots_releases_list.refresh(_releases.all())


func _on_godots_releases_list_item_selected(item: GodotsReleasesListItemControl) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_godots_releases_list_download_and_install_requested(url: String) -> void:
	_godots_downloads.download(
		url, func(abs_zip_path: String) -> void: _godots_install.install(abs_zip_path)
	)


func _on_visibility_changed() -> void:
	if visible and not _data_loaded:
		_async_refetch_data()
