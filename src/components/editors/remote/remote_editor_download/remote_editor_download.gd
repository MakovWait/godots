extends PanelContainer

const uuid = preload("res://addons/uuid.gd")

signal downloaded(abs_zip_path: String)

var _retry_callback

@onready var _progress_bar: ProgressBar = get_node("%ProgressBar")
@onready var _status: Label = get_node("%Status")
@onready var _download :HTTPRequest = $HTTPRequest
@onready var _dismiss_button: TextureButton = %DismissButton
@onready var _title_label: Label = %TitleLabel
@onready var _install_button: Button = %InstallButton
@onready var _retry_button: Button = %RetryButton


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


func start(url, target_abs_dir, file_name, tux_fallback = ""):
	var download_completed_callback = func(result: int, response_code: int,
			headers, body, download_completed_callback: Callable):
#		https://github.com/godotengine/godot/blob/a7583881af5477cd73110cc859fecf7ceaf39bd7/editor/plugins/asset_library_editor_plugin.cpp#L316
		var host = url
		var error_text = null
		var status = ""
		
		if ((result != HTTPRequest.RESULT_SUCCESS or response_code != 200)
				and "github.com" in url and tux_fallback):
			print("Failure!  Falling back to TuxFamily.")
			_download.request_completed.disconnect(download_completed_callback)
			start(tux_fallback, target_abs_dir, file_name, "")
			return
		
		match result:
			HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH, HTTPRequest.RESULT_CONNECTION_ERROR, HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
				error_text = "Connection error, prease try again."
				status = "Can't connect"
			HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
				error_text = "Can't connect to host:" + " " + host
				status = "Can't connect"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_text = "No response from host:" + " " + host
				status = "No response"
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_text = "Can't resolve hostname:" + " " + host
				status = "Can't resolve."
			HTTPRequest.RESULT_REQUEST_FAILED:
				error_text = "Request failed, return code:" + " " + str(response_code)
				status = "Request failed."
			HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN, HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
				error_text = "Cannot save response to:" + " " + _download.download_file
				status = "Write error."
			HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
				error_text = "Request failed, too many redirects"
				status = "Redirect loop."
			HTTPRequest.RESULT_TIMEOUT:
				error_text = "Request failed, timeout"
				status = "Timeout."
			_:
				if response_code != 200:
					error_text = "Request failed, return code:" + " " + str(response_code)
					status = "Failed:" + " " + str(response_code)
		
		_progress_bar.modulate = Color(0, 0, 0, 0)
		
		if error_text:
			$AcceptErrorDialog.dialog_text = "Download error:" + "\n" + error_text
			$AcceptErrorDialog.popup_centered()
			_retry_button.show()
			_status.text = status
		else:
			_install_button.disabled = false
			_status.text = "Ready to install"
			downloaded.emit(_download.download_file)
	
	assert(target_abs_dir.ends_with("/"))
	print("Downloading " + url)
	
	_retry_callback = func(): start(url, target_abs_dir, file_name)
	
	_retry_button.hide()
	_install_button.disabled = true
	_progress_bar.modulate = Color(1, 1, 1, 1)
	_title_label.text = file_name
	
	DirAccess.make_dir_absolute(target_abs_dir)
	if FileAccess.file_exists(target_abs_dir + file_name):
		file_name = uuid.v4().substr(0, 8) + "-" + file_name
	_download.download_file = target_abs_dir + file_name
	var request_err = _download.request(url, [Config.AGENT_HEADER], HTTPClient.METHOD_GET)
	
	if request_err:
		_progress_bar.modulate = Color(0, 0, 0, 0)
		if request_err == 31:
			_status.text = "Invalid URL scheme."
		else:
			_status.text = "Something went wrong."
		return
	
	for connection in _download.request_completed.get_connections():
		_download.request_completed.disconnect(connection.callable)
	_download.request_completed.connect(download_completed_callback.bind(download_completed_callback))
	
	#TODO handle deadlock
	while _download.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		if _download.get_body_size() > 0:
			_progress_bar.max_value = _download.get_body_size()
			_progress_bar.value = _download.get_downloaded_bytes()
		if _download.get_http_client_status() == HTTPClient.STATUS_BODY:
			if _download.get_body_size() > 0:
				_status.text = "Downloading (%s / %s)..." % [
					String.humanize_size(_download.get_downloaded_bytes()),
					String.humanize_size(_download.get_body_size())
				]
			else:
				_status.text = "Downloading (%s)..." % [
					String.humanize_size(_download.get_downloaded_bytes())
				]
		if _download.get_http_client_status() == HTTPClient.STATUS_RESOLVING:
			_status.text = "Resolving..."
			_progress_bar.value = 0
			_progress_bar.max_value = 1
		elif _download.get_http_client_status() == HTTPClient.STATUS_CONNECTING:
			_status.text = "Connecting..."
			_progress_bar.value = 0
			_progress_bar.max_value = 1
		elif _download.get_http_client_status() == HTTPClient.STATUS_REQUESTING:
			_status.text = "Requesting..."
			_progress_bar.value = 0
			_progress_bar.max_value = 1
		await get_tree().create_timer(0.1).timeout


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		_remove_downloaded_file()


func _remove_downloaded_file():
	if _download.download_file:
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(_download.download_file)
		)
