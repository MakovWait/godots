extends Button

const HOUR = 60 * 60
const UPDATES_CACHE_LIFETIME_SEC = 12 * HOUR

var _http_request: HTTPRequest
var _downloading = false
var _link = Config.RELEASES_URL


var _has_update := false:
	set(value):
		_has_update = value
		if value:
			modulate = Color.WHITE
			tooltip_text = "There are updates. Click to visit releases page."
		else:
			modulate = Color(0.5, 0.5, 0.5, 0.5)
			tooltip_text = "No updates."
		queue_redraw()


func _init() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	
	pressed.connect(func():
		OS.shell_open(_link)
	)


func _ready() -> void:
	icon = get_theme_icon("Notification", "EditorIcons")
	flat = true
	_check_updates()


func _notification(what: int) -> void:
	if NOTIFICATION_APPLICATION_FOCUS_IN == what:
		_check_updates()


func _draw() -> void:
	if not _has_update:
		return
	var color = get_theme_color("warning_color", "Editor")
	var button_radius = size.x / 8
	draw_circle(Vector2(button_radius * 2, button_radius * 2), button_radius, color)


func _check_updates():
	if _downloading: 
		return
	var last_checked_unix:int = Config.cache_get_value("update", "last_checked", 0)
	if int(Time.get_unix_time_from_system()) - last_checked_unix > UPDATES_CACHE_LIFETIME_SEC:
		await _update_cache()
	_load_from_cache()


func _update_cache():
	if _downloading:
		return
	_downloading = true
	var response = await _http_get(
		Config.RELEASES_LATEST_API_ENDPOINT, 
		["Accept: application/vnd.github.v3+json"]
	)
	_downloading = false
	var json = JSON.parse_string(
		response[3].get_string_from_utf8()
	) as Dictionary
	if not json:
		return
	Config.cache_set_value("update", "tag_name", json.get("tag_name", Config.VERSION))
	Config.cache_set_value("update", "last_checked", int(Time.get_unix_time_from_system()))
	Config.cache_set_value("update", "link", json.get("html_url", Config.RELEASES_URL))
	Config.cache_save()


func _load_from_cache():
	_has_update = Config.cache_get_value("update", "tag_name") != Config.VERSION
	_link = Config.cache_get_value("update", "link", Config.RELEASES_URL)


func _http_get(url, headers=[]):
	var default_headers = [Config.AGENT_HEADER]
	default_headers.append_array(headers)
	_http_request.request(url, default_headers, HTTPClient.METHOD_GET)
	var response = await _http_request.request_completed
	return response
