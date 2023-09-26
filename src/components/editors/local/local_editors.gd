extends HBoxContainer

signal editor_download_pressed
signal manage_tags_requested(item_tags, all_tags, on_confirm)

const Editors = preload("res://src/services/local_editors.gd")
const dir = preload("res://src/extensions/dir.gd")

@onready var _editors_list: VBoxContainer = $EditorsList
@onready var _sidebar: VBoxContainer = $ScrollContainer/ActionsSidebar
@onready var _download_button: Button = %DownloadButton
@onready var _orphan_editors_button: Button = %OrphanEditorsButton
@onready var _orphan_editors_explorer: ConfirmationDialog = $OrphanEditorExplorer
@onready var _import_button: Button = %ImportButton
@onready var _remove_missing_button = %RemoveMissingButton
@onready var _scan_button = %ScanButton
@onready var _scan_dialog = %ScanDialog
@onready var _refresh_button = %RefreshButton


var _local_editors = Editors.LocalEditors


func _ready() -> void:
	_download_button.icon = get_theme_icon("AssetLib", "EditorIcons")
	_orphan_editors_button.icon = get_theme_icon("Debug", "EditorIcons")
	_import_button.icon = get_theme_icon("Load", "EditorIcons")
	
	_import_button.pressed.connect(func(): import())
	_download_button.pressed.connect(func(): editor_download_pressed.emit())
	
	$EditorImport.imported.connect(func(editor_name, editor_path):
		add(editor_name, editor_path)
	)
	
	_remove_missing_button.confirmed.connect(_remove_missing)
	
	_orphan_editors_button.visible = Config.SHOW_ORPHAN_EDITOR.ret()
	Config.saved.connect(func():
		_orphan_editors_button.visible = Config.SHOW_ORPHAN_EDITOR.ret()
	)
	
	_refresh_button.icon = get_theme_icon("Reload", "EditorIcons")
	_refresh_button.pressed.connect(_refresh)
	
	_scan_button.icon = get_theme_icon("Search", "EditorIcons")
	_scan_button.pressed.connect(func():
		_scan_dialog.current_dir = ProjectSettings.globalize_path(
			Config.VERSIONS_PATH.ret()
		)
		_scan_dialog.popup_centered_ratio(0.5)
	)
	_scan_dialog.dir_to_scan_selected.connect(func(dir_to_scan: String):
		_scan_editors(dir_to_scan)
	)


func init(editors: Editors.LocalEditors):
	_local_editors = editors
	_editors_list.refresh(_local_editors.all())
	_editors_list.sort_items()
	
	_orphan_editors_explorer.init(editors, Config.VERSIONS_PATH.ret())
	_orphan_editors_button.tooltip_text = tr(
		"Check if there are some leaked Godot binaries on the filesystem that can be safely removed. For advanced users."
	)
	_orphan_editors_button.pressed.connect(func():
		_orphan_editors_explorer.before_popup()
		_orphan_editors_explorer.popup_centered_ratio(0.4)
	)
	_update_remove_missing_disabled()


func add(editor_name, exec_path):
	if not _local_editors.has(exec_path):
		var editor = _local_editors.add(editor_name, exec_path)
		_local_editors.save()
		_editors_list.add(editor)


func import(editor_name="", editor_path=""):
	if $EditorImport.visible: 
		return
	$EditorImport.init(editor_name, editor_path)
	$EditorImport.popup_centered()


func _refresh():
	_local_editors.load()
	_editors_list.refresh(_local_editors.all())
	_editors_list.sort_items()
	_update_remove_missing_disabled()


func _remove_missing():
	for e in _local_editors.all().filter(func(x): return not x.is_valid):
		_local_editors.erase(e.path)
	_sidebar.refresh_actions([])
	_local_editors.save()
	_editors_list.refresh(_local_editors.all())
	_editors_list.sort_items()
	_update_remove_missing_disabled()


func _scan_editors(dir_to_scan: String):
	var filter
	if OS.has_feature("windows"):
		filter = func(x: dir.DirListResult):
			var evidences = [
				x.is_file and x.extension == "exe",
				x.file.to_lower().contains("godot_v"),
				not x.file.to_lower().contains("console"),
			]
			return evidences.all(func(is_true): return is_true)
	elif OS.has_feature("macos"):
		filter = func(x: dir.DirListResult):
			var evidences = [
				x.is_dir and x.extension == "app",
				x.file.to_lower().contains("godot")
			]
			return evidences.all(func(is_true): return is_true)
	elif OS.has_feature("linux"):
		filter = func(x: dir.DirListResult):
			var evidences = [
				x.is_file and (
					x.extension.contains("32") or x.extension.contains("64")
				),
				x.file.to_lower().contains("godot_v")
			]
			return evidences.all(func(is_true): return is_true)

	var editors_exec = dir.list_recursive(
		ProjectSettings.globalize_path(dir_to_scan), 
		false,
		filter,
		(func(x: String): 
			return not x.get_file().begins_with("."))
	)
	for editor_exec in editors_exec:
		var editor_exec_path = editor_exec.path
		if _local_editors.has(editor_exec_path):
			continue
		var editor = _local_editors.add(
			utils.guess_editor_name(editor_exec.file),
			editor_exec_path
		)
		_editors_list.add(editor)
	_local_editors.save()


func _update_remove_missing_disabled():
	_remove_missing_button.disabled = len(
		_local_editors.all().filter(func(x): return not x.is_valid)
	) == 0


func _on_editors_list_item_selected(item) -> void:
	_sidebar.refresh_actions(item.get_actions())


func _on_editors_list_item_removed(item_data: Editors.LocalEditor, remove_dir: bool) -> void:
	if remove_dir:
		var base_dir = ProjectSettings.globalize_path(item_data.path.get_base_dir())
		var versions_dir = ProjectSettings.globalize_path(Config.VERSIONS_PATH.ret())
		if not OS.has_feature("linux"):
			base_dir = base_dir.to_lower()
			versions_dir = versions_dir.to_lower()
		if base_dir != versions_dir and base_dir.begins_with(versions_dir):
			dir.remove_recursive(base_dir)
		else:
			Output.push("skipping removing path {%s}" % base_dir)
	if _local_editors.has(item_data.path):
		_local_editors.erase(item_data.path)
		_local_editors.save()
	_sidebar.refresh_actions([])
	_update_remove_missing_disabled()


func _on_editors_list_item_edited(item_data) -> void:
	_local_editors.save()
	_editors_list.sort_items()


func _on_editors_list_item_manage_tags_requested(item_data) -> void:
	var all_tags = Set.new()
	all_tags.append_array(_local_editors.get_all_tags())
	all_tags.append_array(Config.DEFAULT_EDITOR_TAGS.ret())
	manage_tags_requested.emit(
		item_data.tags,
		all_tags.values(),
		func(new_tags):
			item_data.tags = new_tags
			item_data.emit_tags_edited()
			_on_editors_list_item_edited(item_data)
	)
