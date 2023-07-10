extends PanelContainer

signal downloaded(abs_zip_path: String)


@onready var _progress_bar: ProgressBar = get_node("%ProgressBar")
@onready var _status: Label = get_node("%Status")
@onready var _download :HTTPRequest = $HTTPRequest
@onready var _install_button: Button = %InstallButton
@onready var _dismiss_button: TextureButton = %DismissButton


func _ready() -> void:
	add_theme_stylebox_override("panel", get_theme_stylebox("panel", "AssetLib"))
	custom_minimum_size = Vector2(250, 100) * Config.EDSCALE
	
	_dismiss_button.pressed.connect(queue_free)
	_dismiss_button.texture_normal = get_theme_icon("Close", "EditorIcons")


func start(url, target_abs_dir, file_name):
	assert(target_abs_dir.ends_with("/"))

	DirAccess.make_dir_absolute(target_abs_dir)

	_download.download_file = target_abs_dir + file_name
	_download.request(url, [Config.AGENT_HEADER], HTTPClient.METHOD_GET)
	
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
		await get_tree().create_timer(0.1).timeout


func _on_http_request_request_completed(result, response_code, headers, body):
	# TODO check response_code
	downloaded.emit(_download.download_file)


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		if _download.download_file:
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path(_download.download_file)
			)
