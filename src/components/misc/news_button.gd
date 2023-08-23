extends LinkButton

const exml = preload("res://src/extensions/xml.gd")

const HOUR = 60 * 60
const NEWS_CACHE_LIFETIME_SEC = 12 * HOUR

var _http_request: HTTPRequest
var _downloading = false


func _init() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)


func _ready() -> void:
	_check_for_updates()


func _notification(what: int) -> void:
	if NOTIFICATION_APPLICATION_FOCUS_IN == what:
		_check_for_updates()


func _check_for_updates():
	if _downloading: 
		return
	var last_checked_unix:int = Cache.get_value("news", "last_checked", 0)
	if int(Time.get_unix_time_from_system()) - last_checked_unix > NEWS_CACHE_LIFETIME_SEC:
		await _update_cache()
	_load_from_cache()


func _update_cache():
	_downloading = true
	var response = await _http_get("https://godotengine.org/rss.xml")
	_downloading = false
	var body = XML.parse_buffer(response[3])
	var item = exml.smart(body.root).find_smart_child_recursive(
		exml.Filters.by_name("item")
	)
	if not item: 
		return
	var title = item.find_smart_child_recursive(
		exml.Filters.by_name("title")
	)
	var link = item.find_smart_child_recursive(
		exml.Filters.by_name("link")
	)
	Cache.set_value("news", "title", title.o.content)
	Cache.set_value("news", "link", link.o.content)
	Cache.set_value("news", "last_checked", int(Time.get_unix_time_from_system()))
	Cache.save()


func _load_from_cache():
	text = "News: %s" % Cache.get_value("news", "title", "<null>")
	uri = Cache.get_value("news", "link", "")


func _http_get(url, headers=[]):
	var default_headers = [Config.AGENT_HEADER]
	default_headers.append_array(headers)
	_http_request.request(url, default_headers, HTTPClient.METHOD_GET)
	var response = await _http_request.request_completed
	return response
