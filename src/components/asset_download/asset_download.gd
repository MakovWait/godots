class_name AssetDownload
extends PanelContainer

const uuid = preload("res://addons/uuid.gd")

signal downloaded(abs_zip_path: String)
signal download_failed(response_code: int)
signal request_failed(error: int)

var _retry_callback
var _host
var _requesting = false

@onready var _progress_bar: ProgressBar = get_node("%ProgressBar")
@onready var _status: Label = get_node("%Status")
@onready var _download :HTTPRequest = $HTTPRequest
@onready var _dismiss_button: TextureButton = %DismissButton
@onready var _title_label: Label = %TitleLabel
@onready var _install_button: Button = %InstallButton
@onready var _retry_button: Button = %RetryButton

## for customizing icon
## icon.texture = ...
var icon: TextureRect:
	get: return %Icon


func _ready() -> void:
	add_theme_stylebox_override("panel", get_theme_stylebox("panel", "AssetLib"))
	custom_minimum_size = Vector2(250, 100) * Config.EDSCALE
	
	_dismiss_button.pressed.connect(queue_free)
	_dismiss_button.texture_normal = get_theme_icon("Close", "EditorIcons")
	
	_retry_button.pressed.connect(func():
		_remove_downloaded_file()
		if _retry_callback:
			_retry_callback.call()
	)
	
	_install_button.pressed.connect(func():
		downloaded.emit(_download.download_file)
	)
	
	_download.request_completed.connect(func(result: int, response_code: int, headers, body):
		_requesting = false
#		https://github.com/godotengine/godot/blob/a7583881af5477cd73110cc859fecf7ceaf39bd7/editor/plugins/asset_library_editor_plugin.cpp#L316
		var host = _host
		var response = HttpClient.Response.new([
			result, response_code, headers, body
		])
		var status_error_pair = response.to_response_info(host, _download.download_file)
		var error_text = status_error_pair.error_text
		var status = status_error_pair.status
		
		_progress_bar.modulate = Color(0, 0, 0, 0)
		
		if error_text:
			popup_error_dialog(tr("Download Error") + ":\n" + error_text)
			_retry_button.show()
			_status.text = status
			download_failed.emit(response_code)
		else:
			_install_button.disabled = false
			_status.text = tr("Ready to install")
			downloaded.emit(_download.download_file)
	)


func start(url, target_abs_dir, file_name, title_name=null):
	assert(not _requesting)
	assert(target_abs_dir.ends_with("/"))
	
	_requesting = true
	_host = url
	_retry_callback = func(): start(url, target_abs_dir, file_name, title_name)
	
	_retry_button.hide()
	_install_button.disabled = true
	_progress_bar.modulate = Color(1, 1, 1, 1)
	_title_label.text = file_name if title_name == null else title_name
	
	DirAccess.make_dir_absolute(target_abs_dir)
	if FileAccess.file_exists(target_abs_dir + file_name):
		file_name = uuid.v4().substr(0, 8) + "-" + file_name
	_download.download_file = target_abs_dir + file_name
	var request_err = _download.request(url, [Config.AGENT_HEADER], HTTPClient.METHOD_GET)
	
	if request_err:
		_progress_bar.modulate = Color(0, 0, 0, 0)
		if request_err == 31:
			_status.text = tr("Invalid URL scheme.")
		else:
			_status.text = tr("Something went wrong.")
		request_failed.emit(request_err)
		return
	
	#TODO handle deadlock
	while _download.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		if _download.get_body_size() > 0:
			_progress_bar.max_value = _download.get_body_size()
			_progress_bar.value = _download.get_downloaded_bytes()
		if _download.get_http_client_status() == HTTPClient.STATUS_BODY:
			if _download.get_body_size() > 0:
				_status.text = "%s (%s / %s)..." % [
					tr("Downloading"),
					String.humanize_size(_download.get_downloaded_bytes()),
					String.humanize_size(_download.get_body_size())
				]
			else:
				_status.text = "%s (%s)..." % [
					tr("Downloading"),
					String.humanize_size(_download.get_downloaded_bytes())
				]
		if _download.get_http_client_status() == HTTPClient.STATUS_RESOLVING:
			_status.text = tr("Resolving...")
			_progress_bar.value = 0
			_progress_bar.max_value = 1
		elif _download.get_http_client_status() == HTTPClient.STATUS_CONNECTING:
			_status.text = tr("Connecting...")
			_progress_bar.value = 0
			_progress_bar.max_value = 1
		elif _download.get_http_client_status() == HTTPClient.STATUS_REQUESTING:
			_status.text = tr("Requesting...")
			_progress_bar.value = 0
			_progress_bar.max_value = 1
		await get_tree().create_timer(0.1).timeout


func set_status(text):
	_status.text = text


func popup_error_dialog(text):
	$AcceptErrorDialog.dialog_text = text
	$AcceptErrorDialog.popup_centered()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		_remove_downloaded_file()


func _remove_downloaded_file():
	if _download.download_file:
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(_download.download_file)
		)
