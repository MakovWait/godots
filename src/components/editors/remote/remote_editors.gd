extends Control

signal installed(name, abs_path)
signal _loadings_number_changed(value)

const exml = preload("res://src/extensions/xml.gd")
const uuid = preload("res://addons/uuid.gd")


const url = "https://downloads.tuxfamily.org/godotengine/"
const github_url = "https://github.com/godotengine/godot/releases/download/"
const platforms = {
	"X11": {
		"suffixes": ["_x11.64.zip", "_linux.64.zip", "_linux.x86_64.zip", "_linux.x86_32.zip"],
	},
	"OSX": {
		"suffixes": ["_osx.universal.zip", "_macos.universal.zip", "_osx.fat.zip", "_osx32.zip", "_osx64.zip"],
	},
	"Windows": {
		"suffixes": ["_win64.exe.zip", "_win32.exe.zip", "_win64.zip", "_win32.zip"],
	}
}

@export var _editor_download_scene : PackedScene
@export var _editor_install_scene : PackedScene
@export var _remote_editor_direct_link_scene : PackedScene

@onready var tree: Tree = %Tree
@onready var _open_downloads_button: Button = %OpenDownloadsButton
@onready var _direct_link_button: Button = %DirectLinkButton
@onready var _check_box_container: HFlowContainer = %CheckBoxContainer
@onready var _refresh_button: Button = %RefreshButton

var _current_platform
var _root_loaded = false
var _row_filters: Array[RowFilter] = [NotRelatedFilter.new()]
var _current_loadings_number = 0:
	set(value): 
		_current_loadings_number = value
		_loadings_number_changed.emit(value)
var _remote_editors_checkbox_checked = Cache.smart_section(
	Cache.section_of(self) + ".checkbox_checked", true
)
var _editor_downloads


func init(editor_downloads):
	_editor_downloads = editor_downloads


func _ready():
	_detect_platform()
	_setup_tree()
	_setup_checkboxes()
	
	_open_downloads_button.pressed.connect(func():
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Config.DOWNLOADS_PATH.ret()))
	)
	_open_downloads_button.icon = get_theme_icon("Load", "EditorIcons")
	_open_downloads_button.tooltip_text = tr("Open Downloads Dir")
	
	_direct_link_button.icon = get_theme_icon("AssetLib", "EditorIcons")
	_direct_link_button.pressed.connect(func():
		var link_dialog = _remote_editor_direct_link_scene.instantiate()
		add_child(link_dialog)
		link_dialog.popup_centered()
		link_dialog.link_confirmed.connect(func(link):
			download_zip(link, "custom_editor.zip")
		)
	)
	
	_refresh_button.icon = get_theme_icon("Reload", "EditorIcons")
	_refresh_button.pressed.connect(func():
		for c in tree.get_root().get_children():
			c.free()
		_load_data(tree.get_root(), true, true)
	)
	
	_loadings_number_changed.connect(func(value):
		_refresh_button.disabled = value != 0
	)
	


func _setup_checkboxes():
	%CheckBoxPanelContainer.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Tree"))
	
	var checkbox = func(text, filter, button_pressed=false):
		var box = CheckBox.new()
		box.text = text
		box.button_pressed = button_pressed
		if button_pressed:
			_row_filters.append(filter)
		box.toggled.connect(func(pressed):
			if pressed: 
				_row_filters.append(filter)
			else:
				var idx = _row_filters.find(filter)
				_row_filters.remove_at(idx)
			_remote_editors_checkbox_checked.set_value(text, pressed)
			_update_whole_tree_visibility(tree.get_root())
		)
		return box

	var inverted_checkbox = func(text, filter, button_pressed=false):
		var box = CheckBox.new()
		box.text = text
		box.button_pressed = button_pressed
		if not button_pressed:
			_row_filters.append(filter)
		box.toggled.connect(func(pressed):
			if pressed: 
				var idx = _row_filters.find(filter)
				if idx >= 0:
					_row_filters.remove_at(idx)
			else:
				_row_filters.append(filter)
			_remote_editors_checkbox_checked.set_value(text, pressed)
			_update_whole_tree_visibility(tree.get_root())
		)
		return box

	var contains_any = func(words):
		return func(row: TuxfamilyRow): 
			return words.any(func(x): return row.name.to_lower().contains(x.to_lower()))
	
	var _not = func(original):
		return func(row): return not original.call(row)
	
	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("mono"), 
			RowFilter.new(contains_any.call(["mono"])),
			_remote_editors_checkbox_checked.get_value("mono", true)
		)
	)
	
	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("unstable"), 
			RowFilter.new(contains_any.call(["rc", "beta", "alpha", "dev", "fixup"])),
			_remote_editors_checkbox_checked.get_value("unstable", false)
		)
	)
	
	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("any platform"), 
			RowFilter.new(func(row): 
				return row.is_file and row.is_for_different_platform(_current_platform["suffixes"])),
			_remote_editors_checkbox_checked.get_value("any platform", false)
		)
	)

	if not OS.has_feature("macos"):
		var bit
		var opposite 
		if OS.has_feature("32"):
			bit = "32"
			opposite = "64"
		elif OS.has_feature("64"):
			bit = "64"
			opposite = "32"
		if bit:
			_check_box_container.add_child(
				checkbox.call(
					"%s-bit" % bit, 
					RowFilter.new(contains_any.call([opposite])),
					_remote_editors_checkbox_checked.get_value("same-bit", true)
				)
			)

	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("4.x"), 
			RowFilter.new(func(row: TuxfamilyRow): 
				return row.is_possible_version_folder and row.name.begins_with("4")),
			_remote_editors_checkbox_checked.get_value("4.x", true)
		)
	)

	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("3.x"), 
			RowFilter.new(func(row: TuxfamilyRow): 
				return row.is_possible_version_folder and row.name.begins_with("3")),
			_remote_editors_checkbox_checked.get_value("3.x", true)
		)
	)

	_check_box_container.add_child(
		inverted_checkbox.call(
			tr("x.x"), 
			RowFilter.new(func(row: TuxfamilyRow): 
				return row.is_possible_version_folder and not (row.name.begins_with("4") or row.name.begins_with("3"))),
			_remote_editors_checkbox_checked.get_value("x.x", false)
		)
	)



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
		var url = _restore_url(item, Config.USE_GITHUB.ret())
		if Config.USE_GITHUB.ret():
			download_zip(url, file_name, _restore_url(item, false))
		else:
			download_zip(url, file_name)
	)


func download_zip(url, file_name, tux_fallback = ""):
	var editor_download = _editor_download_scene.instantiate()
	_editor_downloads.add_download_item(editor_download)
	editor_download.start(
		url, Config.DOWNLOADS_PATH.ret() + "/", file_name
	)
	editor_download.download_failed.connect(func(response_code):
		Output.push(
			"Failed to download editor: %s" % response_code
		)
	)
	if not tux_fallback.is_empty():
		editor_download.download_failed.connect(func(_response_code):
			Output.push(
				"Attempt to download with tux_fallback: %s" % tux_fallback
			)
			editor_download.start(tux_fallback, Config.DOWNLOADS_PATH.ret() + "/", file_name)
			pass,
			CONNECT_ONE_SHOT + CONNECT_DEFERRED
		)
	editor_download.downloaded.connect(func(abs_path):
		install_zip(
			abs_path, 
			file_name.replace(".zip", "").replace(".", "_"), 
			utils.guess_editor_name(file_name.replace(".zip", "")),
			func(): editor_download.queue_free()
		)
	)


func install_zip(zip_abs_path, root_unzip_folder_name, possible_editor_name, on_install=null):
	var zip_content_dir = _unzip_downloaded(zip_abs_path, root_unzip_folder_name)
	if not DirAccess.dir_exists_absolute(zip_content_dir):
		var accept_dialog = AcceptDialog.new()
		accept_dialog.visibility_changed.connect(func():
			if not accept_dialog.visible:
				accept_dialog.queue_free()
		)
		accept_dialog.dialog_text = tr("Error extracting archive.")
		add_child(accept_dialog)
		accept_dialog.popup_centered()
	else:
		var editor_install = _editor_install_scene.instantiate()
		add_child(editor_install)
		editor_install.init(possible_editor_name, zip_content_dir)
		editor_install.installed.connect(func(name, exec_path):
			installed.emit(name, ProjectSettings.globalize_path(exec_path))
			if on_install:
				on_install.call()
		)
		editor_install.popup_centered()


func _unzip_downloaded(downloaded_abs_path, root_unzip_folder_name):
	var zip_content_dir = "%s/%s" % [Config.VERSIONS_PATH.ret(), root_unzip_folder_name]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(zip_content_dir)):
		zip_content_dir += "-%s" % uuid.v4().substr(0, 8)
	zip_content_dir += "/"
	zip.unzip(downloaded_abs_path, zip_content_dir)
	return zip_content_dir


func _load_data(root: TreeItem, reverse=false, is_tree_root=false):
	_current_loadings_number += 1
	root.set_meta("loaded", true)
	
	var resp = await _http_get(_restore_url(root))
	_current_loadings_number -= 1
	var body = XML.parse_buffer(resp[3])
	
	var tbody = exml.smart(body.root).find_smart_child_recursive(
		exml.Filters.by_name("tbody")
	)
	if not tbody: return
	var nodes = []
	for node in tbody.iter_children_recursive():
		nodes.append(node)
	if reverse:
		nodes.reverse()
	for node in nodes:
		if node.name == "tr":
			var row = TuxfamilyRow.new(node, is_tree_root)
			var tree_item = tree.create_item(root)
			tree_item.set_text(0, row.name)
			tree_item.visible = _should_be_visible(row)
			if row.is_dir:
#				tree_item.set_icon(0, get_theme_icon("folder", "FileDialog"))
				tree_item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
				tree_item.set_icon_modulate(0, get_theme_color("folder_icon_color", "FileDialog"))
				var placeholder = tree.create_item(tree_item)
				placeholder.set_text(0, tr("loading..."))
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
			tree_item.set_meta("row", row)
	if root.has_meta("loading_placeholder"):
		root.get_meta("loading_placeholder").free()


func _should_be_visible(row: TuxfamilyRow):
	if row.is_parent_ref:
		return false
	
	if row.is_file and not row.is_zip:
		return false

	for filter in _row_filters:
		if filter.test(row):
			return false
	
	return true


func _update_whole_tree_visibility(from: TreeItem):
	if not is_instance_valid(from):
		return
	if from.has_meta("row"):
		from.visible = _should_be_visible(from.get_meta("row"))
	for child in from.get_children():
		_update_whole_tree_visibility(child)


func _http_get(url, headers=[]):
	var default_headers = [Config.AGENT_HEADER]
	default_headers.append_array(headers)

	var req = HTTPRequest.new()
	add_child(req)
	req.request(url, default_headers, HTTPClient.METHOD_GET)
	var response = await req.request_completed
	req.queue_free()
	return response


func _restore_url(item: TreeItem, use_github: bool = false):
	var path_steps = []
	var path_src = item
	while path_src != null:
		path_steps.append(path_src.get_meta("url_part"))
		path_src = path_src.get_parent()
	path_steps.reverse()
	
	var result_url = "".join(path_steps) # tux url
	if use_github:
		var github_url = _tux_zip_url_to_github(result_url)
		if github_url:
			return github_url
	return result_url


## Converts a given TuxFamiy URL for a Godot ZIP to a Github URL.[br]
##
## This will only work for all Godot stable Godot releases beginning from
## 3.1.1 (version 2.1.6, which will work, is the exception).  This is due
## to the fact that older releases either aren't available or only provide
## the source code.[br]
##
## Returns [code]""[/code] if [param tux_url] can't be converted to a
## valid Github URL.
func _tux_zip_url_to_github(tux_url: String) -> String:
	var version = tux_url.trim_prefix(url).split("/", false, 1)[0]
	if (not (version >= "3.1.1" or version == "2.1.6")
			or not ".zip" in tux_url or not "-stable_" in tux_url):
		return ""
	
	var result_url = tux_url.replace(url, github_url)
	result_url = result_url.replace("/mono/", "/")
	result_url = result_url.replace("/" + version + "/", "/" + version + "-stable/")
	return result_url


func _on_visibility_changed() -> void:
	if visible and not _root_loaded:
		_load_data(tree.get_root(), true, true)
		_root_loaded = true


class TuxfamilyRow extends RefCounted:
	const exml = preload("res://src/extensions/xml.gd")
	
	var _src: exml.XMLNodeSmart
	var _is_possible_version_folder = false
	
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
	
	var is_possible_version_folder:
		get: return _is_possible_version_folder
	
	func _init(src, is_possible_version_folder=false):
		if src is exml.XMLNodeSmart:
			_src = src
		else:
			_src = exml.smart(src)
		_is_possible_version_folder = is_possible_version_folder
	
	func is_for_different_platform(platform_suffixes):
		var cached_name = name
		return not platform_suffixes.any(func(suffix): return cached_name.ends_with(suffix))


class RowFilter:
	var _delegate
	
	func _init(delegate):
		_delegate = delegate
	
	func test(row: TuxfamilyRow) -> bool:
		return _delegate.call(row)


class SimpleContainsFilter extends RowFilter:
	func _init(what: String):
		super._init(
			func(row: TuxfamilyRow): 
				return row.name.to_lower().contains(what)
		)


class NotRelatedFilter extends RowFilter:
	func _init():
		super._init(
			func(row: TuxfamilyRow): 
				return ["media", "patreon", "testing", "toolchains"].any(
					func(x): return row.name == x
				)
		)
	
