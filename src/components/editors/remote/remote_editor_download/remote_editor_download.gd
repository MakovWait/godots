extends PanelContainer

const uuid = preload("res://addons/uuid.gd")

signal downloaded(abs_zip_path: String)

const _CHECKSUM_FILENAME = "SHA512-SUMS.txt"

var _retry_callback
var _url: String
var _fallback_url: String = "":
	set(new_fallback):
		if "tuxfamily" in new_fallback:
			_mirror_switch_button.text = "Switch to TuxFamily"
		elif "github" in new_fallback:
			_mirror_switch_button.text = "Switch to GitHub"
		elif new_fallback == "":
			pass
		else:
			assert(false, "unknown fallback")
		_fallback_url = new_fallback
var _target_abs_dir: String
var _file_name: String

@onready var _progress_bar: ProgressBar = get_node("%ProgressBar")
@onready var _status: Label = get_node("%Status")
@onready var _download :HTTPRequest = $HTTPRequest
@onready var _dismiss_button: TextureButton = %DismissButton
@onready var _title_label: Label = %TitleLabel
@onready var _install_button: Button = %InstallButton
@onready var _retry_button: Button = %RetryButton
@onready var _mirror_switch_button: Button = %MirrorSwitchButton


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
	
	_mirror_switch_button.pressed.connect(func():
		assert(_fallback_url)
		start(_fallback_url, _target_abs_dir, _file_name, _url)
	)


func start(url, target_abs_dir, file_name, fallback_url = ""):
	var download_completed_callback = func(result: int, response_code: int,
			headers, body, download_completed_callback: Callable):
#		https://github.com/godotengine/godot/blob/a7583881af5477cd73110cc859fecf7ceaf39bd7/editor/plugins/asset_library_editor_plugin.cpp#L316
		var host = url
		var error_text = null
		var status = ""
		
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
			if _fallback_url:
				_mirror_switch_button.show()
			_status.text = status
			return
		else:
			_status.text = "Checking file integrity..."
			if not await _check_file_integrity():
				$AcceptErrorDialog.dialog_text = "Integrity check failed!\n" + \
						"Retry or use another mirror."
				$AcceptErrorDialog.popup_centered()
				_retry_button.show()
				if _fallback_url:
					_mirror_switch_button.show()
					return
		
		_install_button.disabled = false
		_status.text = "Ready to install"
		downloaded.emit(_download.download_file)
	
	assert(target_abs_dir.ends_with("/"))
	print("Downloading " + url)
	
	_url = url
	_target_abs_dir = target_abs_dir
	_file_name = file_name
	_fallback_url = fallback_url
	_retry_callback = func(): start(url, target_abs_dir, file_name, fallback_url)
	
	_retry_button.hide()
	_mirror_switch_button.hide()
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


## Checks integrity of the downloaded file by veryfing that the SHA512
## checksum is correct.  Downloads SHA512-SUMS.txt to do so.[br]
##
## The authenticity of that checksum cannot be verified, however.[br]
##
## Failing to download SHA512-SUMS.txt is treated as success, because, again,
## this method does not verify authenticity of the release.[br]
##
## Returns true on success and false on failure.
func _check_file_integrity() -> bool:
	var checksum_url: String = _url.get_base_dir().path_join(_CHECKSUM_FILENAME)
	var checksum_downloader := HTTPRequest.new()
	checksum_downloader.download_file = _target_abs_dir.get_base_dir() \
			.path_join(_CHECKSUM_FILENAME)
	checksum_downloader.timeout = 10
	checksum_downloader.download_chunk_size = 2048
	print("Downloading ", checksum_url)
	add_child(checksum_downloader)
	checksum_downloader.request(checksum_url)
	var sig_result = await checksum_downloader.request_completed
	var result = sig_result[0]
	var response_code = sig_result[1]
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return true
	
	var globalized_directory_path = ProjectSettings.globalize_path(_target_abs_dir)
	match OS.get_name():
		"Linux", "OpenBSD", "FreeBSD", "NetBSD", "BSD":
			var status = OS.execute("bash", ["-c", "cd " + globalized_directory_path
					+ " && sha512sum -c --ignore-missing --status "
					+ _CHECKSUM_FILENAME])
			return status == 0 or status == 127
		"Windows":
			var certutil_output = []
			OS.execute("certutil", ["-hashfile",
					globalized_directory_path.path_join(_file_name),
					"SHA512"], certutil_output)
			var output_lines = certutil_output[0].split("\n")
			if len(output_lines) <= 2:
				return true
			
			var obtained_sum = output_lines[1].strip_edges()
			if not obtained_sum.is_valid_hex_number():
				return true
			
			var checksum_file_contents = FileAccess.open(_target_abs_dir.path_join(
					_CHECKSUM_FILENAME), FileAccess.READ).get_as_text()
			
			if obtained_sum + "  " + _file_name in checksum_file_contents:
				return true
			else:
				return false
		"macOS":
			return true #TODO
		_:
			return true
	
	checksum_downloader.queue_free()


func _remove_downloaded_file():
	if _download.download_file:
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(_download.download_file)
		)
	var sum_file_path = _target_abs_dir.path_join(_CHECKSUM_FILENAME)
	if FileAccess.file_exists(sum_file_path):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(sum_file_path)
		)
