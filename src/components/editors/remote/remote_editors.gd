extends Control

signal installed(name, abs_path)

const MIRROR_GITHUB_ID = 0
const MIRROR_DEFAULT = MIRROR_GITHUB_ID

const uuid = preload("res://addons/uuid.gd")

@export var _editor_download_scene : PackedScene
@export var _editor_install_scene : PackedScene
@export var _remote_editor_direct_link_scene : PackedScene

@onready var _open_downloads_button: Button = %OpenDownloadsButton
@onready var _direct_link_button: Button = %DirectLinkButton
@onready var _refresh_button: Button = %RefreshButton
@onready var _remote_editors_tree = %RemoteEditorsTree

var _editor_downloads
var _mirror
var _active_mirror_cache = Cache.smart_value(
	self, "active_mirror", true
).map_return_value(func(v):
		return v
)


func init(editor_downloads):
	_editor_downloads = editor_downloads


func _ready():
	_mirror = RemoteEditorsTreeDataSourceGithub.Self.new(
		RemoteEditorsTreeDataSource.RemoteAssetsCallable.new(download_zip)
	)

	_remote_editors_tree.set_data_source(_mirror)
	_active_mirror_cache.put(MIRROR_DEFAULT)
	
	_open_downloads_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Config.DOWNLOADS_PATH.ret()))
	)
	_open_downloads_button.icon = get_theme_icon("Load", "EditorIcons")
	_open_downloads_button.tooltip_text = tr("Open Downloads Dir")
	
	_direct_link_button.icon = get_theme_icon("AssetLib", "EditorIcons")
	_direct_link_button.pressed.connect(func():
		var link_dialog = _remote_editor_direct_link_scene.instantiate()
		add_child(link_dialog)
		link_dialog.popup_centered()
		link_dialog.link_confirmed.connect(func(link):
			download_zip(link, "custom_editor.zip")
		)
	)
	
	_refresh_button.icon = get_theme_icon("Reload", "EditorIcons")
	_refresh_button.tooltip_text = tr("Refresh")
	#_refresh_button.self_modulate = Color(1, 1, 1, 0.6)
	_remote_editors_tree.post_ready(_refresh_button)
	_remote_editors_tree.set_data_source(_mirror)


func download_zip(url, file_name):
	var editor_download = _editor_download_scene.instantiate()
	_editor_downloads.add_download_item(editor_download)
	editor_download.start(
		url, Config.DOWNLOADS_PATH.ret() + "/", file_name
	)
	editor_download.download_failed.connect(func(response_code):
		Output.push(
			"Failed to download editor: %s" % response_code
		)
	)
	editor_download.downloaded.connect(func(abs_path):
		install_zip(
			abs_path, 
			file_name.replace(".zip", "").replace(".", "_"), 
			utils.guess_editor_name(file_name.replace(".zip", "")),
			func(): editor_download.queue_free()
		)
	)


func install_zip(zip_abs_path, root_unzip_folder_name, possible_editor_name, on_install=null):
	var zip_content_dir = _unzip_downloaded(zip_abs_path, root_unzip_folder_name)
	if not DirAccess.dir_exists_absolute(zip_content_dir):
		var accept_dialog = AcceptDialog.new()
		accept_dialog.visibility_changed.connect(func():
			if not accept_dialog.visible:
				accept_dialog.queue_free()
		)
		accept_dialog.dialog_text = tr("Error extracting archive.")
		add_child(accept_dialog)
		accept_dialog.popup_centered()
	else:
		var editor_install = _editor_install_scene.instantiate()
		add_child(editor_install)
		editor_install.init(possible_editor_name, zip_content_dir)
		editor_install.installed.connect(func(p_name, exec_path):
			installed.emit(p_name, ProjectSettings.globalize_path(exec_path))
			if on_install:
				on_install.call()
		)
		editor_install.popup_centered()


func _unzip_downloaded(downloaded_abs_path, root_unzip_folder_name):
	var zip_content_dir = "%s/%s" % [Config.VERSIONS_PATH.ret(), root_unzip_folder_name]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(zip_content_dir)):
		zip_content_dir += "-%s" % uuid.v4().substr(0, 8)
	zip_content_dir += "/"
	zip.unzip(downloaded_abs_path, zip_content_dir)
	return zip_content_dir
