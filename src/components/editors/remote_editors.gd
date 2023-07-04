extends Control

const exml = preload("res://src/extensions/xml.gd")
const url = "https://downloads.tuxfamily.org/godotengine/"

const platforms = {
	"X11": {
		"suffixes": ["_x11.64.zip", "_linux.64.zip", "_linux.x86_64.zip"],
#		"extraction-command" : [
#			"unzip",
#			[
#				"{zip_path}",
#				"-d",
#				"{dest_folder}"
#			],
#		]
	},
	"OSX": {
		"suffixes": ["_osx.universal.zip", "_macos.universal.zip"],
#		"extraction-command" : [
#			"unzip",
#			[
#				"{zip_path}",
#				"-d",
#				"{dest_folder}"
#			],
#		]
	},
	"Windows": {
		"suffixes": ["_win64.exe.zip"],
#		"extraction-command" : [
#			"powershell.exe",
#			[
#				"-command",
#				"\"Expand-Archive '{filename}' '{dest_dir}'\"",
#			]
#		]
	}
}


@onready var tree: Tree = $Tree

var _current_platform


func _ready():
	if OS.has_feature("windows"):
		_current_platform = platforms["Windows"]
	elif OS.has_feature("macos"):
		_current_platform = platforms["OSX"]
	elif OS.has_feature("linux"):
		_current_platform = platforms["X11"]

	var tree_root: TreeItem = tree.create_item()
	tree_root.set_meta("path", url)
	
	load_data(tree_root)

	tree.item_collapsed.connect(
		func(x: TreeItem): 
			var expanded = not x.collapsed
			var not_loaded_yet = not x.has_meta("loaded")
			if expanded and not_loaded_yet:
				load_data(x)
	)

	tree.item_selected.connect(func(): 
		var selected = tree.get_selected()
		if selected != null:
			print(restore_url(selected))
	)


func load_data(root: TreeItem):
	root.set_meta("loaded", true)
	
	var resp = await http_get(restore_url(root))
	var body = XML.parse_buffer(resp[3])
	
	var tbody = exml.smart(body.root).find_smart_child_recursive(
		exml.Filters.by_name("tbody")
	)
	for node in tbody.iter_children_recursive():
		if node.name == "tr":
			var row = TuxfamilyRow.new(node)
			if _should_be_skipped(row):
				continue
			var tree_item = tree.create_item(root)
			tree_item.set_text(0, row.name)
			if row.is_dir:
				var placeholder = tree.create_item(tree_item)
				placeholder.set_text(0, "loading...")
				tree_item.set_meta("loading_placeholder", placeholder)
			tree_item.collapsed = true
			tree_item.set_meta("path", row.href)
	if root.has_meta("loading_placeholder"):
		root.get_meta("loading_placeholder").free()


func _should_be_skipped(row: TuxfamilyRow):
	if row.is_parent_ref:
		return true
	
	if row.is_file and row.is_for_different_platform(_current_platform["suffixes"]):
		return true

	return false


func http_get(url, headers=[]):
	var default_headers = [Config.AGENT_HEADER]
	default_headers.append_array(headers)

	var req = HTTPRequest.new()
	add_child(req)
	req.request(url, default_headers, HTTPClient.METHOD_GET)
	var response = await req.request_completed
	req.queue_free()
	return response


func restore_url(item: TreeItem):
	var path_steps = []
	var path_src = item
	while path_src != null:
		path_steps.append(path_src.get_meta("path"))
		path_src = path_src.get_parent()
	path_steps.reverse()
	return "".join(path_steps)


class TuxfamilyRow extends RefCounted:
	const exml = preload("res://src/extensions/xml.gd")
	
	var _src: exml.XMLNodeSmart
	
	var is_parent_ref:
		get: return self.href == "../"
	
	var href: 
		get: return _src.find_smart_child_recursive(exml.Filters.by_name("a")).attr("href")
	
	var is_dir:
		get: return self.type == "Directory"
	
	var type:
		get: return _src.find_child_recursive(exml.Filters.by_attr("class", "t")).content
	
	var name:
		get: return _src.find_child_recursive(exml.Filters.by_name("a")).content
	
	var is_zip:
		get: return self.type == "application/zip"
	
	var is_file:
		get: return not is_dir
	
	func _init(src):
		if src is exml.XMLNodeSmart:
			_src = src
		else:
			_src = exml.smart(src)
	
	func is_for_different_platform(platform_suffixes):
		var cached_name = name
		return not platform_suffixes.any(func(suffix): return cached_name.ends_with(suffix))
