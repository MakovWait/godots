extends Control

signal installed(name, abs_path)

const exml = preload("res://src/extensions/xml.gd")
const uuid = preload("res://addons/uuid.gd")
const zip = preload("res://src/extensions/zip.gd")


const url = "https://downloads.tuxfamily.org/godotengine/"
const platforms = {
	"X11": {
		"suffixes": ["_x11.64.zip", "_linux.64.zip", "_linux.x86_64.zip", "_linux.x86_32.zip"],
	},
	"OSX": {
		"suffixes": ["_osx.universal.zip", "_macos.universal.zip"],
	},
	"Windows": {
		"suffixes": ["_win64.exe.zip", "_win32.exe.zip", "_win64.zip", "_win32.zip"],
	}
}

@export var _editor_download_scene : PackedScene
@export var _editor_install_scene : PackedScene

@onready var tree: Tree = $VBoxContainer/Tree

var _current_platform
var _root_loaded = false


func _ready():
	_detect_platform()
	_setup_tree()
	
	$VBoxContainer/ScrollContainer.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Tree"))


func _detect_platform():
	if OS.has_feature("windows"):
		_current_platform = platforms["Windows"]
	elif OS.has_feature("macos"):
		_current_platform = platforms["OSX"]
	elif OS.has_feature("linux"):
		_current_platform = platforms["X11"]


func _setup_tree():
	var tree_root: TreeItem = tree.create_item()
	tree_root.set_meta("url_part", url)

	tree.item_collapsed.connect(
		func(x: TreeItem): 
			var expanded = not x.collapsed
			var not_loaded_yet = not x.has_meta("loaded")
			if expanded and not_loaded_yet:
				_load_data(x)
	)

	
	# FIX
	tree.button_clicked.connect(func(item, col, id, mouse):
		if not item.has_meta("file_name"): return
		var file_name = item.get_meta("file_name")
		var editor_download = _editor_download_scene.instantiate()
		%EditorDownloads.add_child(editor_download)
		editor_download.start(_restore_url(item), "user://downloads/", file_name)
		editor_download.downloaded.connect(func(abs_path):
			var editor_install = _editor_install_scene.instantiate()
			add_child(editor_install)
			var zip_content_dir = _unzip_downloaded(abs_path, file_name.replace(".zip", ""))
			var possible_editor_name = _guess_editor_name(file_name)
			editor_install.init(possible_editor_name, zip_content_dir)
			editor_install.installed.connect(func(name, exec_path):
				installed.emit(name, ProjectSettings.globalize_path(exec_path))
				editor_download.queue_free()
			)
			editor_install.popup_centered_ratio()
		)
	)


func _unzip_downloaded(downloaded_abs_path, root_unzip_folder_name):
	var zip_content_dir = "user://versions/%s" % root_unzip_folder_name
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(zip_content_dir)):
		zip_content_dir += "-%s" % uuid.v4().substr(0, 8)
	zip_content_dir += "/"
	zip.unzip(downloaded_abs_path, zip_content_dir)
	return zip_content_dir


func _guess_editor_name(file_name):
	var possible_editor_name = file_name
	var tokens_to_replace = []
	tokens_to_replace.append_array(_current_platform.suffixes)
	tokens_to_replace.append_array(["_", "-"])
	for token in tokens_to_replace:
		possible_editor_name = possible_editor_name.replace(token, " ")
	possible_editor_name = possible_editor_name.strip_edges()
	return possible_editor_name


func _load_data(root: TreeItem):
	root.set_meta("loaded", true)
	
	var resp = await _http_get(_restore_url(root))
	var body = XML.parse_buffer(resp[3])
	
	var tbody = exml.smart(body.root).find_smart_child_recursive(
		exml.Filters.by_name("tbody")
	)
	if not tbody: return
	for node in tbody.iter_children_recursive():
		if node.name == "tr":
			var row = TuxfamilyRow.new(node)
			if _should_be_skipped(row):
				continue
			var tree_item = tree.create_item(root)
			tree_item.set_text(0, row.name)
			if row.is_dir:
#				tree_item.set_icon(0, get_theme_icon("folder", "FileDialog"))
				tree_item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
				tree_item.set_icon_modulate(0, get_theme_color("folder_icon_color", "FileDialog"))
				var placeholder = tree.create_item(tree_item)
				placeholder.set_text(0, "loading...")
				# TODO animate
				placeholder.set_icon(0, get_theme_icon("Progress1", "EditorIcons"))
				tree_item.set_meta("loading_placeholder", placeholder)
			elif row.is_zip:
				tree_item.set_icon(0, get_theme_icon("Godot", "EditorIcons"))
				# FIX save ref to button_click_handler etc.
				var btn_texture: Texture2D = get_theme_icon("AssetLib", "EditorIcons")
				tree_item.add_button(0, btn_texture)
			tree_item.collapsed = true
			tree_item.set_meta("url_part", row.href)
			tree_item.set_meta("file_name", row.name)
	if root.has_meta("loading_placeholder"):
		root.get_meta("loading_placeholder").free()


func _should_be_skipped(row: TuxfamilyRow):
	if len(row.name) > 0 and int(row.name[0]) == 0:
		return true

#	if ["rc", "dev", "alpha", "beta"].any(func(x): return row.name.contains(x)):
#		return true

	if row.is_parent_ref:
		return true
	
	if row.is_file and row.is_for_different_platform(_current_platform["suffixes"]):
		return true

	return false


func _http_get(url, headers=[]):
	var default_headers = [Config.AGENT_HEADER]
	default_headers.append_array(headers)

	var req = HTTPRequest.new()
	add_child(req)
	req.request(url, default_headers, HTTPClient.METHOD_GET)
	var response = await req.request_completed
	req.queue_free()
	return response


func _restore_url(item: TreeItem):
	var path_steps = []
	var path_src = item
	while path_src != null:
		path_steps.append(path_src.get_meta("url_part"))
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
	
	var name: String:
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


func _on_visibility_changed() -> void:
	if visible and not _root_loaded:
		_load_data(tree.get_root())
		_root_loaded = true
