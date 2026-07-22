class_name RssFeedControl
extends HBoxContainer

const HOUR = 60 * 60
const CACHE_LIFETIME_SEC = 6 * HOUR

const FEED_SOURCES: Array[Dictionary] = [
	{
		"name": "Red Indie Games",
		"url": "https://www.youtube.com/feeds/videos.xml?channel_id=UCN5oRj4nn1qVRzOadVc97MQ",
	},
	{
		"name": "GDQuest",
		"url": "https://www.youtube.com/feeds/videos.xml?channel_id=UCxboW7x0jZqFdvMdCFKTMsQ",
	},
	{
		"name": "Godot Engine",
		"url": "https://www.youtube.com/feeds/videos.xml?channel_id=UCKIDvfZD1ZhY4_hhbotf7wA",
	},
	{
		"name": "Godot Blog",
		"url": "https://godotengine.org/rss.xml",
	},
]


@onready var _feed_list := %RssFeedList as VBoxList
@onready var _refresh_button := %RefreshButton as Button

var _http_request: HTTPRequest
var _data_loaded := false
var _fetching := false
var _images_src: RemoteImageSrc.I


func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_refresh_button.icon = get_theme_icon("Reload", "EditorIcons")
	_refresh_button.pressed.connect(_refetch_data)
	_images_src = RemoteImageSrc.LoadFileBuffer.new(
		RemoteImageSrc.FileByUrlCachedEtag.new(),
		get_theme_icon("FileBrokenBigThumb", "EditorIcons")
	)


func init() -> void:
	if visible:
		_refetch_data()


func _refetch_data() -> void:
	if _fetching:
		return
	_fetching = true
	_refresh_button.disabled = true

	var all_items: Array = []
	for source in FEED_SOURCES:
		var feed_items := await _fetch_feed(source)
		all_items.append_array(feed_items)

	# Sort newest first (ISO 8601 and RFC 2822 dates sort lexicographically)
	all_items.sort_custom(func(a: RssFeed.FeedItem, b: RssFeed.FeedItem) -> bool:
		return a.published > b.published
	)

	_feed_list.refresh(all_items)
	_data_loaded = true
	_fetching = false
	_refresh_button.disabled = false


func _fetch_feed(source: Dictionary) -> Array:
	var headers := PackedStringArray([Config.AGENT_HEADER])
	_http_request.request(source.url as String, headers, HTTPClient.METHOD_GET)
	var response: Array = await _http_request.request_completed
	var response_obj := HttpClient.Response.new(response)

	if response_obj.code != 200:
		return []

	var body := XML.parse_buffer(response_obj.body)
	if not body or not body.root:
		return []

	return _parse_feed(body.root, source)


func _parse_feed(root: XMLNode, source: Dictionary) -> Array:
	var items: Array = []
	# YouTube (Atom) uses <entry>, standard RSS uses <item>
	for child: XMLNode in root.children:
		if child.name == "entry" or child.name == "item":
			var item := _parse_entry(child, source.name as String)
			if item and not item.title.is_empty():
				items.append(item)
	return items


func _parse_entry(entry: XMLNode, source_name: String) -> RssFeed.FeedItem:
	var item := RssFeed.FeedItem.new()
	item.source_name = source_name
	var smart_entry := exml.smart(entry)

	# Title
	var title_node := smart_entry.find_smart_child_recursive(
		exml.Filters.by_name("title")
	)
	if title_node:
		item.title = title_node.o.content

	# Link
	# YouTube (Atom): <link rel="alternate" href="..."/>
	# RSS: <link>url</link>
	var link_node := smart_entry.find_smart_child_recursive(
		exml.Filters.by_name("link")
	)
	if link_node:
		if link_node.o.attributes.has("href"):
			item.link = link_node.o.attributes["href"]
		else:
			item.link = link_node.o.content

	# Published date
	# YouTube (Atom): <published>, RSS: <pubDate>
	var pub_node := smart_entry.find_smart_child_recursive(
		exml.Filters.by_name("published")
	)
	if not pub_node:
		pub_node = smart_entry.find_smart_child_recursive(
			exml.Filters.by_name("pubDate")
		)
	if pub_node:
		item.published = pub_node.o.content

	# Thumbnail (YouTube): <media:group><media:thumbnail url="..."/>
	var thumb_node := _find_deep(entry, "media:thumbnail")
	if thumb_node:
		item.thumbnail_url = thumb_node.attributes.get("url", "")

	# Description
	# YouTube: <media:group><media:description>, RSS: <description>
	var desc_node := _find_deep(entry, "media:description")
	if not desc_node:
		var smart_desc := smart_entry.find_smart_child_recursive(
			exml.Filters.by_name("description")
		)
		if smart_desc:
			desc_node = smart_desc.o
	if desc_node:
		item.description = desc_node.content

	return item


func _find_deep(node: XMLNode, name: String) -> XMLNode:
	for child: XMLNode in node.children:
		if child.name == name:
			return child
		var found := _find_deep(child, name)
		if found:
			return found
	return null


func _on_visibility_changed() -> void:
	if visible and not _data_loaded:
		_refetch_data()
