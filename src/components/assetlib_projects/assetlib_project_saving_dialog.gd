extends "res://src/components/projects/install_project_dialog/install_project_dialog.gd"
## A custom project dialog for projects acquired from the asset library.
##
## In additon to defining a poject name and path, it also downloads the
## project from the library.


signal created(path)

const _DIR = preload("res://src/extensions/dir.gd")

## The url of the zip to download.  This is generally the
## [code]download_url[/code] field from asset's description given by
## asset library's API.
var download_url: String

@onready var _project_downloader: HTTPRequest = $ProjectDownloader


func _ready():
	dialog_hide_on_ok = false
	super._ready()


func _save_assetlib_project():
	_set_message(tr("Downloading..."), null)
	_message_label.modulate = Color(1, 1, 1, 1)
	get_ok_button().disabled = true
	
	_project_downloader.download_file = Config.DOWNLOADS_PATH.ret().path_join(download_url.get_file())
	var err = _project_downloader.request(download_url)
	if err != OK:
		_error(error_string(err))
		get_ok_button().disabled = false
	
	while _project_downloader.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		if _project_downloader.get_http_client_status() == HTTPClient.STATUS_BODY:
			if _project_downloader.get_body_size() > 0:
				_message_label.text = "%s (%s / %s)..." % [
					tr("Downloading"),
					String.humanize_size(_project_downloader.get_downloaded_bytes()),
					String.humanize_size(_project_downloader.get_body_size())
				]
			else:
				_message_label.text = "%s (%s)..." % [
					tr("Downloading"),
					String.humanize_size(_project_downloader.get_downloaded_bytes())
				]
		if _project_downloader.get_http_client_status() == HTTPClient.STATUS_RESOLVING:
			_message_label.text = tr("Resolving...")
		elif _project_downloader.get_http_client_status() == HTTPClient.STATUS_CONNECTING:
			_message_label.text = tr("Connecting...")
		elif _project_downloader.get_http_client_status() == HTTPClient.STATUS_REQUESTING:
			_message_label.text = tr("Requesting...")
		await get_tree().create_timer(0.1).timeout


func _on_project_downloader_request_completed(result: int,
		response_code: int, _headers: PackedStringArray,
		_body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_error(tr("Download failed."))
		get_ok_button().disabled = false
		_download_cleanup()
		return
	
	var dir = _project_path_line_edit.text.strip_edges()
	var project_name = _project_name_edit.text.strip_edges()
	
	var zip = ZIPReader.new()
	zip.open(_project_downloader.download_file)
	var err = _unzip_to_path(zip, dir)
	if err != OK:
		assert(err != ERR_FILE_NOT_FOUND)
		_error(error_string(err))
		get_ok_button().disabled = false
		_download_cleanup()
		return

	var cfg = ConfigFile.new()
	err = cfg.load(dir.path_join("project.godot"))
	if err != OK:
		_error(error_string(err))
		get_ok_button().disabled = false
		_download_cleanup()
		return
	cfg.set_value("application", "config/name", project_name)
	err = cfg.save(dir.path_join("project.godot"))
	if err != OK:
		_error(error_string(err))
		get_ok_button().disabled = false
		_download_cleanup()
		return
	
	_success("Download completed.")
	_download_cleanup()
	created.emit(dir)


## A procedure that unzips a zip file to a target directory, keeping the
## target directory as root, rather than the zip's root directory.
func _unzip_to_path(zip: ZIPReader, destiny: String) -> Error:
	var files = zip.get_files()
	var err
	
	for zip_file_name in files:
		if zip_file_name == files[0]:
			continue
		var target_file_name = destiny.path_join(zip_file_name.split("/", false, 1)[1])
		if zip_file_name.ends_with("/"):
			err = DirAccess.make_dir_recursive_absolute(target_file_name)
			if err != OK:
				return err
		else:
			var file_contents = zip.read_file(zip_file_name)
			var file = FileAccess.open(target_file_name, FileAccess.WRITE)
			if not file:
				return FileAccess.get_open_error()
			file.store_buffer(file_contents)
			file.close()
	return OK


## Removes any download/install artifacts.
func _download_cleanup():
	DirAccess.remove_absolute(Config.DOWNLOADS_PATH.ret().path_join(download_url.get_file()))
